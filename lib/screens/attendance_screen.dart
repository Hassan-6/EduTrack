import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';
import '../services/auth_provider.dart';
import '../services/firebase_service.dart';
import 'camera_overlay_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final TextEditingController _otpController = TextEditingController();
  
  // FIX: Initialize with default values
  Student _currentStudent = Student(name: 'Loading...', rollNumber: 'N/A');
  bool _isLoadingStudent = true;

  bool _isPhotoTaken = false;
  bool _isCodeEntered = false;
  String? _capturedPhotoPath;
  Map<String, dynamic>? _locationData;

  @override
  void initState() {
    super.initState();
    _otpController.addListener(() {
      setState(() {
        _isCodeEntered = _otpController.text.length == 6;
      });
    });
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser != null) {
        final userProfile = await FirebaseService.getUserProfile(authProvider.currentUser!.uid);
        if (userProfile != null) {
          setState(() {
            _currentStudent = Student(
              name: userProfile['name'] ?? 'Student',
              rollNumber: userProfile['rollNumber'] ?? 'N/A',
            );
            _isLoadingStudent = false;
          });
        } else {
          setState(() {
            _currentStudent = Student(name: 'Student', rollNumber: 'N/A');
            _isLoadingStudent = false;
          });
        }
      }
    } catch (e) {
      print('Error loading student data: $e');
      setState(() {
        _currentStudent = Student(name: 'Student', rollNumber: 'N/A');
        _isLoadingStudent = false;
      });
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _takePhoto() async {
    // Unfocus the OTP field before opening camera
    FocusScope.of(context).unfocus();
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CameraOverlayScreen(),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _isPhotoTaken = true;
        _capturedPhotoPath = result['photoPath']; // Store the photo path
        _locationData = {
          'latitude': result['latitude'],
          'longitude': result['longitude'],
          'altitude': result['altitude'],
          'address': result['address'],
          'accuracy': result['accuracy'],
          'speed': result['speed'],
          'speedAccuracy': result['speedAccuracy'],
          'heading': result['heading'],
          'headingAccuracy': result['headingAccuracy'],
          'timestamp': result['timestamp'],
          'isMocked': result['isMocked'],
        };
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo captured with location data embedded!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _submitAttendance() async {
    if (!_isCodeEntered) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the attendance code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_isPhotoTaken) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please take a photo for verification'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get the entered OTP
    final enteredOtp = _otpController.text.trim();
    
    try {
      // Get current user ID
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser == null) {
        throw Exception('User not authenticated');
      }
      final studentId = authProvider.currentUser!.uid;
      
      print('=== Submitting Attendance ===');
      print('Student ID: $studentId');
      print('Entered OTP: $enteredOtp');
      
      // Get student's enrolled courses
      final userProfile = await FirebaseService.getUserProfile(studentId);
      if (userProfile == null) {
        throw Exception('User profile not found');
      }
      
      print('User profile data: $userProfile');
      
      // Get enrolled courses from user profile
      final enrolledCourses = userProfile['enrolledCourses'] as List<dynamic>? ?? [];
      print('Enrolled courses from profile: $enrolledCourses');
      
      // If no enrolled courses in profile, try to find all courses where student is enrolled
      List<String> coursesToCheck = [];
      if (enrolledCourses.isEmpty) {
        print('No enrolledCourses in profile, searching all courses where student is enrolled...');
        final allCourses = await FirebaseService.getAllCoursesWhereStudentEnrolled(studentId);
        coursesToCheck = allCourses;
        print('Found ${coursesToCheck.length} courses where student is enrolled');
      } else {
        coursesToCheck = enrolledCourses.map((c) => c.toString()).toList();
      }
      
      if (coursesToCheck.isEmpty) {
        throw Exception('You are not enrolled in any courses. Please enroll in a course first.');
      }
      
      // First, verify OTP is valid (before uploading photo to save time)
      bool verified = false;
      String? verifiedCourseId;
      String? verifiedCourseTitle;
      
      for (String courseId in coursesToCheck) {
        print('Checking course: $courseId with OTP: $enteredOtp');
        final success = await FirebaseService.verifyAttendance(
          courseId: courseId,
          studentId: studentId,
          otp: enteredOtp,
          photoURL: null, // Don't pass photo yet, just verify OTP
        );
        
        if (success) {
          verified = true;
          verifiedCourseId = courseId;
          // Get course title for display
          final courseDoc = await FirebaseService.getCourseById(courseId);
          verifiedCourseTitle = courseDoc?['title'] ?? 'Course';
          print('Attendance verified for course: $verifiedCourseTitle');
          break;
        }
      }
      
      if (!verified) {
        throw Exception('Invalid or expired OTP. Please check the code and try again.');
      }
      
      print('=== ATTENDANCE VERIFIED SUCCESSFULLY ===');
      print('Verified course ID: $verifiedCourseId');
      print('Captured photo path: $_capturedPhotoPath');
      print('Location data: $_locationData');
      
      // Save location data directly (skipping photo upload as storage is not available)
      if (verifiedCourseId != null && _locationData != null) {
        print('Saving location data to Firestore...');
        await FirebaseService.updateAttendanceLocation(
          courseId: verifiedCourseId,
          studentId: studentId,
          otp: enteredOtp,
          locationData: _locationData!,
        );
        print('Location data saved successfully');
      } else {
        print('WARNING: Course ID or location data is null');
        print('Course ID: $verifiedCourseId');
        print('Location data: $_locationData');
      }

      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Attendance Submitted',
                    style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Text(
                'Your attendance has been successfully recorded for $verifiedCourseTitle.',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'OK',
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
              ),
            ],
          ),
        );
        
        // Clear the OTP field
        _otpController.clear();
        setState(() {
          _isCodeEntered = false;
          _isPhotoTaken = false;
        });
      }
    } catch (e) {
      print('Error submitting attendance: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
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
          'Attendance',
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Student Details Card
            _buildStudentDetailsCard(),
            const SizedBox(height: 16),

            // Attendance Code Card
            _buildAttendanceCodeCard(),
            const SizedBox(height: 16),

            // Location & Verification Card
            _buildVerificationCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
      
      // Submit Button
      bottomNavigationBar: Container(
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
            onTap: _submitAttendance,
            child: Center(
              child: Text(
                'Submit Attendance',
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
    );
  }

  Widget _buildStudentDetailsCard() {
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
          Text(
            'Student Details',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),

          // Full Name
          _buildDetailField(
            label: 'Full Name',
            value: _currentStudent.name,
          ),
          const SizedBox(height: 16),

          // Roll Number
          _buildDetailField(
            label: 'Roll Number',
            value: _currentStudent.rollNumber,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailField({required String label, required String value}) {
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.black.withOpacity(0.2) 
                : const Color(0xFFF9FAFB), // THEME: Adaptive background
            border: Border.all(color: Theme.of(context).dividerColor), // THEME: Dynamic border
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceCodeCard() {
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
          Text(
            "Instructor's Attendance Code",
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Enter the 6-digit code shared by your instructor to confirm attendance',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), // THEME: Dynamic text
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),

          // Single OTP Input Field
          TextField(
            controller: _otpController,
            textAlign: TextAlign.center,
            maxLength: 6,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              counterText: '',
              hintText: 'Enter 6-digit code',
              hintStyle: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                fontSize: 16,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onBackground,
              letterSpacing: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard() {
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
          Text(
            'Location & Verification',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Please confirm your presence by sharing your location and a quick photo',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), // THEME: Dynamic text
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),

          // Photo Capture Option
          _buildVerificationOption(
            icon: Icons.camera_alt,
            title: 'Take Photo',
            subtitle: 'Capture verification photo',
            isCompleted: _isPhotoTaken,
            onTap: _takePhoto,
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isCompleted ? const Color(0xFF5CD6C0) : Theme.of(context).dividerColor, // THEME: Dynamic border
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isCompleted ? const Color(0xFFF0FDF4) : Theme.of(context).cardColor, // THEME: Dynamic background
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isCompleted ? const Color(0xFF5CD6C0) : Theme.of(context).colorScheme.onSurface.withOpacity(0.6), // THEME: Dynamic icon
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                color: isCompleted ? Colors.black : Theme.of(context).colorScheme.onBackground, // Black when completed
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                color: isCompleted ? Colors.black87 : Theme.of(context).colorScheme.onSurface.withOpacity(0.6), // Dark when completed
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            if (isCompleted) ...[
              const SizedBox(height: 8),
              const Icon(
                Icons.check_circle,
                size: 16,
                color: Color(0xFF5CD6C0),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class Student {
  final String name;
  final String rollNumber;

  Student({
    required this.name,
    required this.rollNumber,
  });
}

// Attendance History Screen
class AttendanceHistoryScreen extends StatelessWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          'Attendance History',
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Attendance history and statistics would be displayed here.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), // THEME: Dynamic text
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}