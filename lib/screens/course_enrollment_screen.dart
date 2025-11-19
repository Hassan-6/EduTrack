import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';
import '../services/firebase_service.dart';

class CourseEnrollmentScreen extends StatefulWidget {
  const CourseEnrollmentScreen({super.key});

  @override
  State<CourseEnrollmentScreen> createState() => _CourseEnrollmentScreenState();
}

class _CourseEnrollmentScreenState extends State<CourseEnrollmentScreen> {
  bool _otpVerified = false;
  bool _showOtpInput = false;
  
  final TextEditingController _otpController = TextEditingController();
  final List<TextEditingController> _otpDigitControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (index) => FocusNode());
  
  // Dummy course data that would be fetched after OTP verification
  Map<String, dynamic>? _courseData;

  void _showOtpSection() {
    setState(() {
      _showOtpInput = true;
    });
  }

  void _verifyOtp() {
    // Simulate OTP verification
    if (_otpController.text.length == 6) {
      setState(() {
        _otpVerified = true;
        _showOtpInput = false;
        // Simulate fetching course data after successful OTP verification
        _courseData = {
          'courseName': 'Fundamentals of Organic Chemistry',
          'courseCode': 'CHEM 340',
          'department': 'Chemistry',
          'section': 'A',
          'instructor': 'Dr. Ali Mahmood',
          'schedule': 'Mon/Wed/Fri 10:00 AM - 11:30 AM',
          'credits': 3,
          'room': 'Science Building 205',
          'semester': 'Fall 2024',
        };
      });
    } else {
      // Show error for invalid OTP
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 6-digit OTP'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _sendEnrollmentRequest() async {
    if (_courseData == null) return;
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor, // THEME: Dynamic background
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Theme.of(context).primaryColor), // THEME: Dynamic progress
            const SizedBox(height: 16),
            Text(
              'Sending enrollment request...',
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );

    try {
      // Get current user
      final currentUser = FirebaseService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Send enrollment request to Firebase
      await FirebaseService.enrollInCourse(currentUser.uid, _courseData!);
      
      if (!mounted) return;
      
      Navigator.pop(context); // Remove loading dialog
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor, // THEME: Dynamic background
          title: Text(
            'Enrollment Request Sent',
            style: TextStyle(color: Theme.of(context).colorScheme.onBackground), // THEME: Dynamic text
          ),
          content: Text(
            'Your enrollment request for ${_courseData!['courseName']} has been sent to ${_courseData!['instructor']} for approval. You will be notified when your request is processed.',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface, // THEME: Dynamic text
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close success dialog
                Navigator.pop(context); // Go back to courses screen
              },
              child: Text(
                'OK',
                style: TextStyle(color: Theme.of(context).primaryColor), // THEME: Dynamic button
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      Navigator.pop(context); // Remove loading dialog
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(
            'Error',
            style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
          ),
          content: Text(
            'Failed to send enrollment request: ${e.toString()}',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
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
    }
  }

  void _restartProcess() {
    setState(() {
      _otpVerified = false;
      _showOtpInput = false;
      _courseData = null;
      _otpController.clear();
      for (var controller in _otpDigitControllers) {
        controller.clear();
      }
    });
  }

  void _handleOtpInput(String value, int index) {
    if (value.length == 1 && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
    
    // Update the main OTP controller
    _otpController.text = _otpDigitControllers.map((c) => c.text).join();
  }

  @override
  void initState() {
    super.initState();
    
    // Add listeners to OTP digit controllers
    for (int i = 0; i < _otpDigitControllers.length; i++) {
      _otpDigitControllers[i].addListener(() {
        if (_otpDigitControllers[i].text.isNotEmpty && i < 5) {
          _otpFocusNodes[i + 1].requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _otpDigitControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    _otpController.dispose();
    super.dispose();
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.network(
                          'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0SCOMduDvxzkW25UhUo3%2Fde5a2088-5c73-4a6c-844d-510b8aac3a31.png',
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
                  
                  // Title
                  Expanded(
                    child: Center(
                      child: Text(
                        'Course Enrollment',
                        style: GoogleFonts.inter(
                          color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  
                  // Spacer for alignment
                  const SizedBox(width: 30),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // OTP Entry Section
                    _buildOtpSection(themeProvider),
                    
                    const SizedBox(height: 24),
                    
                    // Course Details Section (shown after OTP verification)
                    if (_otpVerified && _courseData != null)
                      _buildCourseDetailsSection(),
                  ],
                ),
              ),
            ),

            // Send Enrollment Button (shown after OTP verification)
            if (_otpVerified && _courseData != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(24),
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
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
                  gradient: themeProvider.gradient, // THEME: Dynamic gradient
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _sendEnrollmentRequest,
                    child: Center(
                      child: Text(
                        'Send Enrollment Request',
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

  Widget _buildOtpSection(ThemeProvider themeProvider) {
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
            'OTP Verification',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Enter the 6-digit OTP provided by your instructor to view course details and enroll.',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface, // THEME: Dynamic text
              fontSize: 14,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Initial state - Show Enter OTP button
          if (!_showOtpInput && !_otpVerified)
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x19000000),
                    spreadRadius: 0,
                    offset: Offset(0, 4),
                    blurRadius: 8,
                  )
                ],
                gradient: themeProvider.gradient, // THEME: Dynamic gradient
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _showOtpSection,
                  child: Center(
                    child: Text(
                      'Enter OTP',
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
          
          // OTP Input State
          if (_showOtpInput && !_otpVerified)
            Column(
              children: [
                Text(
                  'Enter the 6-digit OTP:',
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                
                // OTP Input Fields - Larger size like instructor attendance screen
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      return Container(
                        width: 44, // Reduced from 48 to fit better
                        height: 52, // Reduced from 56 to fit better
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor, // THEME: Dynamic background
                          border: Border.all(color: Theme.of(context).dividerColor), // THEME: Dynamic border
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: TextField(
                            controller: _otpDigitControllers[index],
                            focusNode: _otpFocusNodes[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            style: GoogleFonts.inter(
                              color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
                              fontSize: 20, // Slightly larger font
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: const InputDecoration(
                              counterText: '',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (value) => _handleOtpInput(value, index),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Submit OTP Button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x19000000),
                        spreadRadius: 0,
                        offset: Offset(0, 4),
                        blurRadius: 8,
                      )
                    ],
                    gradient: themeProvider.gradient, // THEME: Dynamic gradient
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _verifyOtp,
                      child: Center(
                        child: Text(
                          'Submit OTP',
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
          
          // OTP Verified State - Centered content
          if (_otpVerified)
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center, // Add this line
              children: [
                const SizedBox(height: 16),
                Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'OTP Verified Successfully!',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF10B981),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Course details loaded below',
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onSurface, // THEME: Dynamic text
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCourseDetailsSection() {
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
            'Course Details',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Details displayed after OTP is successfully verified',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface, // THEME: Dynamic text
              fontSize: 14,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Course Details Form
          Column(
            children: [
              _buildDetailField('Course Name', _courseData!['courseName']),
              const SizedBox(height: 16),
              _buildDetailField('Course Code', _courseData!['courseCode']),
              const SizedBox(height: 16),
              _buildDetailField('Department', _courseData!['department']),
              const SizedBox(height: 16),
              _buildDetailField('Section', _courseData!['section']),
              const SizedBox(height: 16),
              _buildDetailField('Instructor', _courseData!['instructor']),
              const SizedBox(height: 16),
              _buildDetailField('Schedule', _courseData!['schedule']),
              const SizedBox(height: 16),
              _buildDetailField('Credits', '${_courseData!['credits']} credits'),
              const SizedBox(height: 16),
              _buildDetailField('Room', _courseData!['room']),
              const SizedBox(height: 16),
              _buildDetailField('Semester', _courseData!['semester']),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface, // THEME: Dynamic text
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
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
            maxLines: null,
          ),
        ),
      ],
    );
  }
}