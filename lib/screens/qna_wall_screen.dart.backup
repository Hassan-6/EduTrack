import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../widgets/bottom_nav_bar.dart';
import 'profile_viewer_screen.dart';
import 'profile_screen.dart';
import '../utils/theme_provider.dart';

class QAWallScreen extends StatefulWidget {
  const QAWallScreen({super.key});

  @override
  State<QAWallScreen> createState() => _QAWallScreenState();
}

class _QAWallScreenState extends State<QAWallScreen> {
  int _currentBottomNavIndex = 2; // Q&A is active
  String _selectedFilter = 'All';
  bool _showBookmarksOnly = false;

  final List<String> _userCourses = ['Math 101', 'Computer Science', 'Physics 201', 'Chemistry'];

  final List<Question> _questions = [
    Question(
      id: '1',
      userProfile: UserProfile(
        name: 'Ali Khan',
        username: '@ali.khan',
        major: 'Computer Science Major',
        age: '22',
        rollNumber: '251694200',
        phoneNumber: '+92 300 1234567',
        email: 'ali.khan@university.edu',
        semester: '5th Semester',
        cgpa: '3.8',
      ),
      course: 'Math 101',
      title: 'How do I solve quadratic equations using the quadratic formula?',
      content: "I'm having trouble understanding how to apply the quadratic formula to solve equations like x² + 5x + 6 = 0. Can someone explain step by step? For example, the question is: 'Solve the quadratic equation 2x^2 – 7x + 6 = 0 using the quadratic formula' How do I solve this and what would be the answer?",
      timeAgo: '2 hours ago',
      replies: [
        Reply(
          userProfile: UserProfile(
            name: 'Qasim Rizvi',
            username: '@qasim.rizvi',
            major: 'Mathematics Major',
            age: '23',
            rollNumber: '251694201',
            phoneNumber: '+92 311 2345678',
            email: 'qasim.rizvi@university.edu',
            semester: '6th Semester',
            cgpa: '3.9',
          ),
          content: 'The quadratic formula is x = [-b ± √(b² - 4ac)] / 2a. For 2x² - 7x + 6 = 0, a=2, b=-7, c=6. First calculate discriminant: (-7)² - 4*2*6 = 49 - 48 = 1. Then x = [7 ± √1] / 4 = [7 ± 1] / 4. So x = (7+1)/4 = 2 or x = (7-1)/4 = 1.5.',
          timeAgo: '1 hour ago',
        ),
        Reply(
          userProfile: UserProfile(
            name: 'Sara Ahmed',
            username: '@sara.ahmed',
            major: 'Computer Science Major',
            age: '21',
            rollNumber: '251694202',
            phoneNumber: '+92 322 3456789',
            email: 'sara.ahmed@university.edu',
            semester: '4th Semester',
            cgpa: '3.7',
          ),
          content: 'Great explanation by Qasim! Just to add, always remember to check your answers by plugging them back into the original equation to verify.',
          timeAgo: '45 minutes ago',
        ),
      ],
      isBookmarked: false,
    ),
    Question(
      id: '2',
      userProfile: UserProfile(
        name: 'Sarah Miller',
        username: '@sarah.miller',
        major: 'Computer Science Major',
        age: '22',
        rollNumber: '251694203',
        phoneNumber: '+92 333 4567890',
        email: 'sarah.miller@university.edu',
        semester: '5th Semester',
        cgpa: '3.6',
      ),
      course: 'Computer Science',
      title: "What's the difference between arrays and linked lists in data structures?",
      content: "I'm studying for my data structures exam and I'm confused about when to use arrays vs linked lists. What are the main differences in terms of performance and use cases?",
      timeAgo: '4 hours ago',
      replies: [
        Reply(
          userProfile: UserProfile(
            name: 'David Chen',
            username: '@david.chen',
            major: 'Computer Science Major',
            age: '24',
            rollNumber: '251694204',
            phoneNumber: '+92 344 5678901',
            email: 'david.chen@university.edu',
            semester: '7th Semester',
            cgpa: '3.8',
          ),
          content: 'Arrays have O(1) access time but O(n) for insertions/deletions. Linked lists have O(n) access but O(1) for insertions/deletions at known positions. Use arrays when you need fast random access, linked lists when you do frequent insertions/deletions.',
          timeAgo: '3 hours ago',
        ),
      ],
      isBookmarked: true,
    ),
    Question(
      id: '3',
      userProfile: UserProfile(
        name: 'Alex Lee',
        username: '@alex.lee',
        major: 'Physics Major',
        age: '23',
        rollNumber: '251694205',
        phoneNumber: '+92 355 6789012',
        email: 'alex.lee@university.edu',
        semester: '6th Semester',
        cgpa: '3.5',
      ),
      course: 'Physics 201',
      title: "Can someone explain Newton's third law with practical examples?",
      content: "I understand the basic concept but I'm struggling to apply it to real-world situations. Could someone provide some everyday examples of action-reaction pairs?",
      timeAgo: '1 day ago',
      replies: [],
      isBookmarked: false,
    ),
  ];

  List<Question> get _filteredQuestions {
    var filtered = _questions;
    
    // Filter by course
    if (_selectedFilter != 'All') {
      filtered = filtered.where((q) => q.course == _selectedFilter).toList();
    }
    
    // Filter by bookmarks
    if (_showBookmarksOnly) {
      filtered = filtered.where((q) => q.isBookmarked).toList();
    }
    
    return filtered;
  }

  void _askNewQuestion() {
    String? selectedCourse;
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor, // THEME: Dynamic background
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ask a Question',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
                ),
              ),
              const SizedBox(height: 16),
              
              // Course Selection
              DropdownButtonFormField<String>(
                value: selectedCourse,
                decoration: InputDecoration(
                  labelText: 'Select Course',
                  labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface), // THEME: Dynamic text
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).dividerColor), // THEME: Dynamic border
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).primaryColor), // THEME: Dynamic focus border
                  ),
                ),
                items: _userCourses.map((String course) {
                  return DropdownMenuItem<String>(
                    value: course,
                    child: Text(
                      course,
                      style: TextStyle(color: Theme.of(context).colorScheme.onBackground), // THEME: Dynamic text
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  selectedCourse = newValue;
                },
              ),
              const SizedBox(height: 12),
              
              // Question Title
              TextField(
                controller: titleController,
                style: TextStyle(color: Theme.of(context).colorScheme.onBackground), // THEME: Dynamic text
                decoration: InputDecoration(
                  hintText: 'Enter your question title...',
                  hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)), // THEME: Dynamic hint
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).dividerColor), // THEME: Dynamic border
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).primaryColor), // THEME: Dynamic focus border
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Question Content
              TextField(
                controller: contentController,
                style: TextStyle(color: Theme.of(context).colorScheme.onBackground), // THEME: Dynamic text
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Add more details about your question...',
                  hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)), // THEME: Dynamic hint
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).dividerColor), // THEME: Dynamic border
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).primaryColor), // THEME: Dynamic focus border
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Post Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (selectedCourse != null && titleController.text.isNotEmpty) {
                      _postNewQuestion(
                        selectedCourse!,
                        titleController.text,
                        contentController.text,
                      );
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor, // THEME: Dynamic button
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Post Question'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _postNewQuestion(String course, String title, String content) {
    final newQuestion = Question(
      id: '${_questions.length + 1}',
      userProfile: UserProfile(
        name: 'Oneeb Tariq', // Current user
        username: '@oneeb.tariq',
        major: 'Computer Science Major',
        age: '27',
        rollNumber: '251694198',
        phoneNumber: '+92 322 4994498',
        email: 'oneeb.tariq@university.edu',
        semester: '6th Semester',
        cgpa: '3.75',
      ),
      course: course,
      title: title,
      content: content,
      timeAgo: 'Just now',
      replies: [],
      isBookmarked: false,
    );
    
    setState(() {
      _questions.insert(0, newQuestion);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Question posted successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _toggleBookmark(String questionId) {
    setState(() {
      final question = _questions.firstWhere((q) => q.id == questionId);
      question.isBookmarked = !question.isBookmarked;
    });
  }

  void _viewQuestionDetails(Question question) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionDetailScreen(question: question),
      ),
    );
  }

  void _navigateToUserProfile(UserProfile userProfile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileViewerScreen(userProfile: userProfile),
      ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor, // THEME: Dynamic background
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Filter Questions',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
              ),
            ),
            const SizedBox(height: 16),
            
            // Course Filter
            DropdownButtonFormField<String>(
              value: _selectedFilter,
              decoration: InputDecoration(
                labelText: 'Filter by Course',
                labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface), // THEME: Dynamic text
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).dividerColor), // THEME: Dynamic border
                ),
              ),
              items: ['All', ..._userCourses].map((String course) {
                return DropdownMenuItem<String>(
                  value: course,
                  child: Text(
                    course,
                    style: TextStyle(color: Theme.of(context).colorScheme.onBackground), // THEME: Dynamic text
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedFilter = newValue!;
                });
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
            
            // Bookmarks Filter
            SwitchListTile(
              title: Text(
                'Show Bookmarks Only',
                style: TextStyle(color: Theme.of(context).colorScheme.onBackground), // THEME: Dynamic text
              ),
              value: _showBookmarksOnly,
              onChanged: (bool value) {
                setState(() {
                  _showBookmarksOnly = value;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
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
        Navigator.pushReplacementNamed(context, '/todo');
        break;
      case 2:
        // Already on Q&A, do nothing
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Q&A Wall',
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: Theme.of(context).colorScheme.onBackground), // THEME: Dynamic icon
            onPressed: _showFilterOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor, // THEME: Dynamic background
              border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)), // THEME: Dynamic border
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Questions', _filteredQuestions.length.toString()),
                _buildStatItem('Active', _filteredQuestions.length.toString()),
                _buildStatItem('Bookmarked', _questions.where((q) => q.isBookmarked).length.toString()),
              ],
            ),
          ),
          // Questions List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredQuestions.length,
              itemBuilder: (context, index) {
                final question = _filteredQuestions[index];
                return _buildQuestionCard(question);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentBottomNavIndex,
        onTap: _onBottomNavTapped,
      ),
      floatingActionButton: _buildQnAFloatingActionButton(themeProvider),
    );
  }

  Widget _buildQnAFloatingActionButton(ThemeProvider themeProvider) {
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
          onTap: _askNewQuestion,
          child: Center(
            child: Image.network(
              'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0SCOMduDvxzkW25UhUo3%2F1acf3707-fc14-48b1-a087-6a99c88d6baa.png',
              width: 16,
              height: 16,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface, // THEME: Dynamic text
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(Question question) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with user info and course
          Row(
            children: [
              // User Avatar (Clickable)
              GestureDetector(
                onTap: () => _navigateToUserProfile(question.userProfile),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8FBFE6),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Center(
                    child: Text(
                      question.userProfile.name.split(' ').map((n) => n[0]).join(),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // User info and time
              Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToUserProfile(question.userProfile),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question.userProfile.name,
                        style: GoogleFonts.inter(
                          color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        question.timeAgo,
                        style: GoogleFonts.inter(
                          color: Theme.of(context).colorScheme.onSurface, // THEME: Dynamic text
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Course tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1), // THEME: Dynamic background
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  question.course,
                  style: GoogleFonts.inter(
                    color: Theme.of(context).primaryColor, // THEME: Dynamic text
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Question Title
          Text(
            question.title,
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Question Content Preview
          Text(
            question.content,
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface, // THEME: Dynamic text
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          // Footer with actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Replies count
              Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface, // THEME: Dynamic icon
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${question.replies.length} ${question.replies.length == 1 ? 'reply' : 'replies'}',
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onSurface, // THEME: Dynamic text
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              // Action buttons
              Row(
                children: [
                  IconButton(
                    onPressed: () => _toggleBookmark(question.id),
                    icon: Icon(
                      question.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      size: 20,
                      color: question.isBookmarked ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.onSurface, // THEME: Dynamic icon
                    ),
                  ),
                  IconButton(
                    onPressed: () => _viewQuestionDetails(question),
                    icon: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface, // THEME: Dynamic icon
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class Question {
  String id;
  UserProfile userProfile;
  String course;
  String title;
  String content;
  String timeAgo;
  List<Reply> replies;
  bool isBookmarked;

  Question({
    required this.id,
    required this.userProfile,
    required this.course,
    required this.title,
    required this.content,
    required this.timeAgo,
    required this.replies,
    required this.isBookmarked,
  });
}

class Reply {
  UserProfile userProfile;
  String content;
  String timeAgo;

  Reply({
    required this.userProfile,
    required this.content,
    required this.timeAgo,
  });
}

// Updated Question Detail Screen (No App Bar or Bottom Nav)
class QuestionDetailScreen extends StatefulWidget {
  final Question question;

  const QuestionDetailScreen({super.key, required this.question});

  @override
  State<QuestionDetailScreen> createState() => _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends State<QuestionDetailScreen> {
  final TextEditingController _replyController = TextEditingController();

  void _postReply() {
    if (_replyController.text.trim().isNotEmpty) {
      final newReply = Reply(
        userProfile: UserProfile(
          name: 'Oneeb Tariq', // Current user
          username: '@oneeb.tariq',
          major: 'Computer Science Major',
          age: '27',
          rollNumber: '251694198',
          phoneNumber: '+92 322 4994498',
          email: 'oneeb.tariq@university.edu',
          semester: '6th Semester',
          cgpa: '3.75',
        ),
        content: _replyController.text,
        timeAgo: 'Just now',
      );

      setState(() {
        widget.question.replies.insert(0, newReply);
        _replyController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reply posted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _navigateToUserProfile(UserProfile userProfile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileViewerScreen(userProfile: userProfile),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background, // THEME: Dynamic background
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header (No App Bar)
            Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor, // THEME: Dynamic background
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
                          Image.network(
                            'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0SCOMduDvxzkW25UhUo3%2F011f3e0d-4e44-491c-9f8b-d8b4a7e4c7be.png',
                            width: 11,
                            height: 11,
                            fit: BoxFit.contain,
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
                    'Question Details',
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question Card
                    _buildQuestionDetailCard(),
                    const SizedBox(height: 24),
                    // Replies Section
                    Text(
                      'Replies (${widget.question.replies.length})',
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Replies List
                    ...widget.question.replies.map((reply) => _buildReplyCard(reply)),
                    const SizedBox(height: 24),
                    // Write Reply Section
                    _buildReplyInput(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionDetailCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              // User Avatar (Clickable)
              GestureDetector(
                onTap: () => _navigateToUserProfile(widget.question.userProfile),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8FBFE6),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Center(
                    child: Text(
                      widget.question.userProfile.name.split(' ').map((n) => n[0]).join(),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToUserProfile(widget.question.userProfile),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Posted by',
                        style: GoogleFonts.inter(
                          color: Theme.of(context).colorScheme.onSurface, // THEME: Dynamic text
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.question.userProfile.name,
                        style: GoogleFonts.inter(
                          color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        widget.question.timeAgo,
                        style: GoogleFonts.inter(
                          color: Theme.of(context).colorScheme.onSurface, // THEME: Dynamic text
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1), // THEME: Dynamic background
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  widget.question.course,
                  style: GoogleFonts.inter(
                    color: Theme.of(context).primaryColor, // THEME: Dynamic text
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Question Title
          Text(
            widget.question.title,
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          // Question Content
          Text(
            widget.question.content,
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface, // THEME: Dynamic text
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyCard(Reply reply) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // THEME: Dynamic card
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor), // THEME: Dynamic border
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reply Header
          Row(
            children: [
              // User Avatar (Clickable)
              GestureDetector(
                onTap: () => _navigateToUserProfile(reply.userProfile),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8FBFE6),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Center(
                    child: Text(
                      reply.userProfile.name.split(' ').map((n) => n[0]).join(),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToUserProfile(reply.userProfile),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reply.userProfile.name,
                        style: GoogleFonts.inter(
                          color: Theme.of(context).colorScheme.onSurface, // THEME: Dynamic text
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        reply.timeAgo,
                        style: GoogleFonts.inter(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), // THEME: Dynamic text
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Reply Content
          Text(
            reply.content,
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyInput() {
    return Container(
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Write your reply',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _replyController,
            style: TextStyle(color: Theme.of(context).colorScheme.onBackground), // THEME: Dynamic text
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Write here...',
              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)), // THEME: Dynamic hint
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).dividerColor), // THEME: Dynamic border
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).primaryColor), // THEME: Dynamic focus border
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _postReply,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor, // THEME: Dynamic button
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              child: Text(
                'Post Answer',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}