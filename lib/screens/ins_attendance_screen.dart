import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/route_manager.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/firebase_service.dart';
import '../services/auth_provider.dart';

class InsAttendanceScreen extends StatefulWidget {
  const InsAttendanceScreen({super.key});

  @override
  State<InsAttendanceScreen> createState() => _InsAttendanceScreenState();
}

class _InsAttendanceScreenState extends State<InsAttendanceScreen> {
  int _currentBottomNavIndex = 0; // Default to Home since attendance isn't in bottom nav
  String _generatedOtp = '';
  int _timeRemaining = 0;
  bool _isOtpGenerated = false;
  bool _isAttendanceRecorded = false;
  String? _selectedCourseId;
  DateTime _selectedDate = DateTime.now();
  int _totalStudents = 0;
  int _verifiedAttendance = 0;
  String? _currentSessionId;
  StreamSubscription? _attendanceStreamSubscription;

  List<Map<String, dynamic>> _courses = [];
  bool _isLoadingCourses = true;

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _loadInstructorCourses();
  }

  @override
  void dispose() {
    _attendanceStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadInstructorCourses() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser == null) {
        print('No current user found');
        setState(() {
          _isLoadingCourses = false;
        });
        return;
      }

      print('Loading courses for instructor: ${authProvider.currentUser!.uid}');
      final courses = await FirebaseService.getInstructorCourses(authProvider.currentUser!.uid);
      
      setState(() {
        _courses = courses;
        if (_courses.isNotEmpty) {
          _selectedCourseId = _courses[0]['id'];
          _loadCourseStudentCount(_selectedCourseId!);
        }
        _isLoadingCourses = false;
      });
      
      print('Loaded ${_courses.length} courses');
    } catch (e) {
      print('Error loading instructor courses: $e');
      setState(() {
        _isLoadingCourses = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading courses: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadCourseStudentCount(String courseId) async {
    try {
      final count = await FirebaseService.getCourseEnrolledStudentsCount(courseId);
      setState(() {
        _totalStudents = count;
      });
    } catch (e) {
      print('Error loading student count: $e');
    }
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
        Navigator.pushNamedAndRemoveUntil(
          context,
          RouteManager.getToDoListRoute(),
          (route) => route.settings.name == RouteManager.getMainMenuRoute(),
        );
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

  void _onBackPressed() {
    Navigator.pushReplacementNamed(context, RouteManager.getMainMenuRoute());
  }

  Future<void> _generateOtp() async {
    if (_selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a course first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Generate random 6-digit OTP
      final otp = _generateRandomOtp();
      
      // Create attendance session in Firebase
      final sessionId = await FirebaseService.createAttendanceSession(
        courseId: _selectedCourseId!,
        otp: otp,
        durationMinutes: 2,
      );

      setState(() {
        _generatedOtp = otp;
        _currentSessionId = sessionId;
        _isOtpGenerated = true;
        _isAttendanceRecorded = false;
        _timeRemaining = 120; // 2 minutes in seconds
        _verifiedAttendance = 0;
      });

      // Start countdown timer
      _startCountdown();
      
      // Start listening to real-time attendance updates
      _listenToAttendanceUpdates();
      
      print('OTP generated: $otp for course: $_selectedCourseId');
    } catch (e) {
      print('Error generating OTP: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating OTP: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _generateRandomOtp() {
    String otp = '';
    for (int i = 0; i < 6; i++) {
      otp += _random.nextInt(10).toString();
    }
    return otp;
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_timeRemaining > 0 && _isOtpGenerated) {
        setState(() {
          _timeRemaining--;
        });
        _startCountdown();
      } else if (_timeRemaining == 0) {
        setState(() {
          _isOtpGenerated = false;
        });
      }
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _recordAttendance() async {
    if (_selectedCourseId == null || _currentSessionId == null) return;

    try {
      // Close attendance session in Firebase
      await FirebaseService.closeAttendanceSession(
        courseId: _selectedCourseId!,
        sessionId: _currentSessionId!,
      );

      setState(() {
        _isAttendanceRecorded = true;
        _isOtpGenerated = false;
      });

      _attendanceStreamSubscription?.cancel();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Attendance recorded! $_verifiedAttendance/$_totalStudents students verified'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error recording attendance: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error recording attendance: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Listen to real-time attendance updates from Firebase
  void _listenToAttendanceUpdates() {
    if (_selectedCourseId == null || _currentSessionId == null) return;

    _attendanceStreamSubscription?.cancel();
    _attendanceStreamSubscription = FirebaseService.getAttendanceSessionStream(
      courseId: _selectedCourseId!,
      sessionId: _currentSessionId!,
    ).listen((snapshot) {
      if (!snapshot.exists) return;
      
      final data = snapshot.data() as Map<String, dynamic>;
      final verifiedStudents = data['verifiedStudents'] as List<dynamic>? ?? [];
      
      if (mounted) {
        setState(() {
          _verifiedAttendance = verifiedStudents.length;
        });
      }
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
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
          onPressed: _onBackPressed,
        ),
        title: Text(
          'Attendance',
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onBackground,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.onBackground),
            onPressed: () {
              // Additional options menu
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            
            // OTP Generation Card
            _buildOtpCard(),
            const SizedBox(height: 16),
            
            // Attendance Information Card
            _buildAttendanceInfoCard(),
            const SizedBox(height: 16),
            
            // Record Attendance Button (only visible when OTP is generated)
            if (_isOtpGenerated || _isAttendanceRecorded) 
              _buildRecordAttendanceButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentBottomNavIndex,
        onTap: _onBottomNavTapped,
      ),
    );
  }

  Widget _buildOtpCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Generate OTP',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onBackground,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'An OTP will be generated for this class. It will expire after 2 minutes.',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          
          // Generate OTP Button (only show if no OTP is active and attendance not recorded)
          if (!_isOtpGenerated && !_isAttendanceRecorded)
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF4E9FEC), Color(0xFF5CD6C0)],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x19000000),
                    blurRadius: 15,
                    offset: Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Color(0x19000000),
                    blurRadius: 6,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _generateOtp,
                  child: Center(
                    child: Text(
                      'Generate OTP',
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
          
          // OTP Display
          if (_isOtpGenerated) ...[
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                height: 48,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      return Container(
                        width: 40,
                        height: 48,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          border: Border.all(color: Theme.of(context).dividerColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            _generatedOtp[index],
                            style: GoogleFonts.inter(
                              color: Theme.of(context).colorScheme.onBackground,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Time Remaining: ${_formatTime(_timeRemaining)}',
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onBackground,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttendanceInfoCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendance Information',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          
          // Course and Date Row
          Row(
            children: [
              // Course Selection
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Course',
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _isLoadingCourses
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(12.0),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : _courses.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Text(
                                      'No courses found',
                                      style: GoogleFonts.inter(
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                )
                              : DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedCourseId,
                                    isExpanded: true,
                                    dropdownColor: Colors.white,
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _selectedCourseId = newValue!;
                                        _loadCourseStudentCount(newValue);
                                      });
                                    },
                                    items: _courses.map((course) {
                                      return DropdownMenuItem<String>(
                                        value: course['id'] as String,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          child: Text(
                                            course['title'] ?? 'Unnamed Course',
                                            style: GoogleFonts.inter(
                                              color: Colors.black87,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              
              // Date Selection
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date',
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _selectDate,
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0x7F9CA3AF),
                          border: Border.all(color: Theme.of(context).dividerColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
                                style: GoogleFonts.inter(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Always show attendance counts (even after recording)
          const SizedBox(height: 20),
          
          // Total Students
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Students',
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: const Color(0x7F9CA3AF),
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      _totalStudents.toString(),
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Verified Attendance
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verified Attendance',
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: const Color(0x7F9CA3AF),
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      _verifiedAttendance.toString(),
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    if (_isOtpGenerated) // Show "Live" badge only when OTP is active
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Live',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordAttendanceButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 44),
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF4E9FEC), Color(0xFF5CD6C0)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x19000000),
            blurRadius: 15,
            offset: Offset(0, 10),
          ),
          BoxShadow(
            color: Color(0x19000000),
            blurRadius: 6,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _recordAttendance,
          child: Center(
            child: Text(
              _isAttendanceRecorded ? 'Attendance Recorded' : 'Record Attendance',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}