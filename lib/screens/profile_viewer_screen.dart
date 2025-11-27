import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'profile_screen.dart';
import '../utils/theme_provider.dart';

class ProfileViewerScreen extends StatelessWidget {
  final UserProfile userProfile;

  const ProfileViewerScreen({
    super.key,
    required this.userProfile,
  });

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
          'Profile',
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
              _buildProfileHeader(context),
              const SizedBox(height: 24),
              // Personal Details (semester shown for students)
              _buildPersonalDetails(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // THEME: Dynamic card
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.black.withOpacity(0.3) 
                : Colors.black.withOpacity(0.05), // THEME: Adaptive shadow
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Profile Picture
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: themeProvider.primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(60),
              border: Border.all(
                color: themeProvider.primaryColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              ProfileIcons.getIcon(userProfile.profileIconIndex),
              size: 60,
              color: themeProvider.primaryColor,
            ),
          ),
          const SizedBox(height: 16),

          // Name and Username
          Text(
            userProfile.name,
            style: GoogleFonts.poppins(
              color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          // Role + descriptor: Roll Number for students, Department for instructors on separate lines
          Column(
            children: [
              // First line: Roll Number or Department
              Text(
                userProfile.rollNumber.isNotEmpty
                    ? userProfile.rollNumber
                    : (userProfile.major.isNotEmpty ? userProfile.major : ''),
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              // Second line: Student or Instructor
              Text(
                userProfile.rollNumber.isNotEmpty ? 'Student' : 'Instructor',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Academic summary removed for viewer; semester is shown in Personal Details for students

  // Academic item helper removed — not used after layout changes


  Widget _buildPersonalDetails(BuildContext context) {
    // Determine user type based on presence of rollNumber
    final isStudent = userProfile.rollNumber.isNotEmpty;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // THEME: Dynamic card
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.black.withOpacity(0.3) 
                : Colors.black.withOpacity(0.05), // THEME: Adaptive shadow
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Details',
            style: GoogleFonts.poppins(
              color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Name (both)
          _buildDetailField(
            context,
            label: 'Full Name',
            value: userProfile.name,
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),

          // Student: Roll Number
          if (isStudent) ...[
            _buildDetailField(
              context,
              label: 'Roll Number',
              value: userProfile.rollNumber,
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 16),
          ],

          // Student: Semester
          if (isStudent) ...[
            _buildDetailField(
              context,
              label: 'Semester',
              value: userProfile.semester,
              icon: Icons.school_outlined,
            ),
            const SizedBox(height: 16),
          ],

          // Instructor: Department
          if (!isStudent) ...[
            _buildDetailField(
              context,
              label: 'Department',
              value: userProfile.major,
              icon: Icons.account_balance_outlined,
            ),
            const SizedBox(height: 16),
          ],

          // Phone Number (both)
          _buildDetailField(
            context,
            label: 'Phone Number',
            value: userProfile.phoneNumber,
            icon: Icons.phone_outlined,
          ),
          const SizedBox(height: 16),

          // Email (both)
          _buildDetailField(
            context,
            label: 'Email',
            value: userProfile.email,
            icon: Icons.email_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailField(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.black.withOpacity(0.2) 
            : const Color(0xFFF9FAFB), // THEME: Adaptive background
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurface, // THEME: Dynamic icon
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.onSurface, // THEME: Dynamic text
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}