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
  final List<TextEditingController> _codeControllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  
  // FIX: Initialize with default values
  Student _currentStudent = Student(name: 'Loading...', rollNumber: 'N/A');
  bool _isLoadingStudent = true;

  bool _isPhotoTaken = false;
  bool _isCodeEntered = false;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _focusNodes.length; i++) {
      _focusNodes[i].addListener(() {
        if (!_focusNodes[i].hasFocus && i < _focusNodes.length - 1) {
          FocusScope.of(context).requestFocus(_focusNodes[i + 1]);
        }
      });
    }
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
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onCodeChanged(String value, int index) {
    if (value.length == 1 && index < _codeControllers.length - 1) {
      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
    } else if (value.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }

    final allEntered = _codeControllers.every(
        (controller) => controller.text.isNotEmpty && controller.text.length == 1);
    setState(() {
      _isCodeEntered = allEntered;
    });
  }

  void _takePhoto() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CameraOverlayScreen(),
      ),
    );

    if (result != null) {
      setState(() {
        _isPhotoTaken = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo captured with location data embedded!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _submitAttendance() {
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor, // THEME: Dynamic background
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(
              'Attendance Submitted',
              style: TextStyle(color: Theme.of(context).colorScheme.onBackground), // THEME: Dynamic text
            ),
          ],
        ),
        content: Text(
          'Your attendance has been successfully recorded for today.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface), // THEME: Dynamic text
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(color: Theme.of(context).primaryColor), // THEME: Dynamic button
            ),
          ),
        ],
      ),
    );
  }

  void _viewAttendanceHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AttendanceHistoryScreen(),
      ),
    );
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
        actions: [
          IconButton(
            icon: Icon(Icons.history, color: Theme.of(context).colorScheme.onBackground), // THEME: Dynamic icon
            onPressed: _viewAttendanceHistory,
          ),
        ],
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

          // Code Input Boxes
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 40,
                  height: 48,
                  child: TextField(
                    controller: _codeControllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Theme.of(context).dividerColor), // THEME: Dynamic border
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Theme.of(context).primaryColor), // THEME: Dynamic focus border
                      ),
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
                    ),
                    onChanged: (value) => _onCodeChanged(value, index),
                  ),
                );
              }),
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
                color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), // THEME: Dynamic text
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