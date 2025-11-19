import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/route_manager.dart';
import '../widgets/bottom_nav_bar.dart';

class InsAttendanceScreen extends StatefulWidget {
  const InsAttendanceScreen({super.key});

  @override
  State<InsAttendanceScreen> createState() => _InsAttendanceScreenState();
}

class _InsAttendanceScreenState extends State<InsAttendanceScreen> {
  int _currentBottomNavIndex = 1;
  String _generatedOtp = '';
  int _timeRemaining = 0;
  bool _isOtpGenerated = false;
  bool _isAttendanceRecorded = false;
  String _selectedCourse = 'CSCS 100 D';
  DateTime _selectedDate = DateTime.now();
  int _totalStudents = 30;
  int _verifiedAttendance = 0;

  final List<String> _courses = [
    'CSCS 100 D',
    'MATH 101 A',
    'PHYS 102 B',
    'CHEM 103 C'
  ];

  final Random _random = Random();

  void _onBottomNavTapped(int index) {
    setState(() {
      _currentBottomNavIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, RouteManager.getMainMenuRoute());
        break;
      case 1:
        // Already on attendance, do nothing
        break;
      case 2:
        Navigator.pushReplacementNamed(context, RouteManager.getQnARoute());
        break;
      case 3:
        Navigator.pushReplacementNamed(context, RouteManager.getProfileRoute());
        break;
    }
  }

  void _onBackPressed() {
    Navigator.pushReplacementNamed(context, RouteManager.getMainMenuRoute());
  }

  void _generateOtp() {
    setState(() {
      _isOtpGenerated = true;
      _isAttendanceRecorded = false;
      _timeRemaining = 120; // 2 minutes in seconds
      _verifiedAttendance = 0; // Reset when new OTP is generated
      
      // Generate random 6-digit OTP with different numbers
      _generatedOtp = _generateRandomOtp();
      
      // Start countdown timer
      _startCountdown();
      
      // Start simulating attendance updates
      _simulateAttendanceUpdates();
    });
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

  void _recordAttendance() {
    setState(() {
      _isAttendanceRecorded = true;
      _isOtpGenerated = false; // Stop OTP when attendance is recorded
    });
    
    // Simulate recording attendance
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Attendance recorded successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Simulate real-time attendance updates
  void _simulateAttendanceUpdates() {
    if (_isOtpGenerated && _timeRemaining > 0 && _verifiedAttendance < _totalStudents) {
      Future.delayed(Duration(seconds: 1 + _random.nextInt(3)), () {
        if (_isOtpGenerated && _verifiedAttendance < _totalStudents) {
          setState(() {
            _verifiedAttendance++;
          });
          _simulateAttendanceUpdates();
        }
      });
    }
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E1E1E)),
          onPressed: _onBackPressed,
        ),
        title: Text(
          'Attendance',
          style: GoogleFonts.inter(
            color: const Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF1E1E1E)),
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
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF3F4F6)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            spreadRadius: 0,
            offset: Offset(0, 1),
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
              color: const Color(0xFF1F2937),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'An OTP will be generated for this class. It will expire after 2 minutes.',
            style: GoogleFonts.inter(
              color: const Color(0xFF6B7280),
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
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            _generatedOtp[index],
                            style: GoogleFonts.inter(
                              color: const Color(0xFF1F2937),
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
                color: const Color(0xFF1F2937),
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
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF3F4F6)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            spreadRadius: 0,
            offset: Offset(0, 1),
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
              color: const Color(0xFF1F2937),
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
                        color: const Color(0xFF4B5563),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0x7F9CA3AF),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCourse,
                          isExpanded: true,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedCourse = newValue!;
                            });
                          },
                          items: _courses.map((String course) {
                            return DropdownMenuItem<String>(
                              value: course,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  course,
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF1F2937),
                                    fontSize: 14,
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
                        color: const Color(0xFF4B5563),
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
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF1F2937),
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: Color(0xFF6B7280),
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
                  color: const Color(0xFF4B5563),
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
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      _totalStudents.toString(),
                      style: GoogleFonts.inter(
                        color: const Color(0xFF1F2937),
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
                  color: const Color(0xFF4B5563),
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
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      _verifiedAttendance.toString(),
                      style: GoogleFonts.inter(
                        color: const Color(0xFF1F2937),
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