import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../utils/route_manager.dart';
import 'settings_screen.dart';
import '../utils/theme_provider.dart';
import '../services/firebase_service.dart';
import '../services/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _currentBottomNavIndex = 3;
  bool _isLoading = true;
  bool _isEditing = false;

  late UserProfile _userProfile;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _rollNumberController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _semesterController = TextEditingController();
  final TextEditingController _cgpaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize with default values to prevent late initialization error
    _userProfile = UserProfile(
      name: '',
      username: '@user',
      major: 'Not specified',
      age: '',
      rollNumber: '',
      phoneNumber: '',
      email: '',
      semester: 'Not specified',
      cgpa: 'N/A',
    );
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;
      
      if (currentUser == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // Fetch user data from Firestore
      final profileData = await FirebaseService.getUserProfile(currentUser.uid);
      
      if (mounted) {
        setState(() {
          _userProfile = UserProfile(
            name: profileData?['name'] ?? currentUser.displayName ?? 'User',
            username: '@${profileData?['name'] ?? 'user'}'.replaceAll(' ', '.').toLowerCase(),
            major: profileData?['major'] ?? 'Not specified',
            age: profileData?['age'] ?? '',
            rollNumber: profileData?['rollNumber'] ?? '',
            phoneNumber: profileData?['phoneNumber'] ?? '',
            email: profileData?['email'] ?? currentUser.email ?? '',
            semester: profileData?['semester'] ?? 'Not specified',
            cgpa: profileData?['cgpa'] ?? 'N/A',
          );
          _isLoading = false;
          _initializeControllers();
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _initializeControllers() {
    _nameController.text = _userProfile.name;
    _rollNumberController.text = _userProfile.rollNumber;
    _phoneController.text = _userProfile.phoneNumber;
    _emailController.text = _userProfile.email;
    _semesterController.text = _userProfile.semester;
    _cgpaController.text = _userProfile.cgpa;
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _saveChanges();
      }
    });
  }

  Future<void> _saveChanges() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;
      
      if (currentUser == null) return;

      // Update Firestore with new profile data
      await FirebaseService.updateUserProfile(currentUser.uid, {
        'name': _nameController.text,
        'rollNumber': _rollNumberController.text,
        'phoneNumber': _phoneController.text,
        'email': _emailController.text,
        'semester': _semesterController.text,
        'cgpa': _cgpaController.text,
      });

      setState(() {
        _userProfile.name = _nameController.text;
        _userProfile.rollNumber = _rollNumberController.text;
        _userProfile.phoneNumber = _phoneController.text;
        _userProfile.email = _emailController.text;
        _userProfile.semester = _semesterController.text;
        _userProfile.cgpa = _cgpaController.text;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _changeProfilePicture() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Profile Picture'),
        content: const Text('Profile picture change functionality would go here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context, 
                '/registration', 
                (route) => false
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _currentBottomNavIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, RouteManager.getMainMenuRoute());
        break;
      case 1:
        Navigator.pushReplacementNamed(context, RouteManager.getToDoListRoute());
        break;
      case 2:
        Navigator.pushReplacementNamed(context, RouteManager.getQnARoute());
        break;
      case 3:
        break;
    }
  }

  void _onBackPressed() {
    Navigator.pushReplacementNamed(context, RouteManager.getMainMenuRoute());
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    // Show loading screen while profile is being loaded
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background, // THEME: Dynamic background
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor, // THEME: Dynamic app bar
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onBackground), // THEME: Dynamic icon color
          onPressed: _onBackPressed,
        ),
        title: Text(
          'Profile',
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text color
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.onBackground), // THEME: Dynamic icon color
            onPressed: _showMoreOptions,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(themeProvider),
            const SizedBox(height: 24),
            _buildAcademicSummary(),
            const SizedBox(height: 24),
            _buildPersonalDetails(),
            const SizedBox(height: 24),
            _buildActionButtons(themeProvider),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentBottomNavIndex,
        onTap: _onBottomNavTapped,
      )
    );
  }

  Widget _buildProfileHeader(ThemeProvider themeProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // THEME: Dynamic card color
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
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF8FBFE6), // Keep this as brand color
                  borderRadius: BorderRadius.circular(60),
                ),
                child: const Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _changeProfilePicture,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: themeProvider.primaryColor, // THEME: Dynamic accent color
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _userProfile.name,
            style: GoogleFonts.poppins(
              color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text color
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // THEME: Dynamic card color
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
            'Academic Summary',
            style: GoogleFonts.poppins(
              color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text color
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildEditableField(
                  label: 'Semester',
                  value: _userProfile.semester,
                  controller: _semesterController,
                  isEditing: _isEditing,
                  icon: Icons.school_outlined,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildEditableField(
                  label: 'CGPA',
                  value: _userProfile.cgpa,
                  controller: _cgpaController,
                  isEditing: _isEditing,
                  icon: Icons.grade_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildPersonalDetails() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // THEME: Dynamic card color
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
              color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text color
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          _buildEditableField(
            label: 'Full Name',
            value: _userProfile.name,
            controller: _nameController,
            isEditing: _isEditing,
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),

          _buildEditableField(
            label: 'Roll Number',
            value: _userProfile.rollNumber,
            controller: _rollNumberController,
            isEditing: _isEditing,
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 16),

          _buildEditableField(
            label: 'Phone Number',
            value: _userProfile.phoneNumber,
            controller: _phoneController,
            isEditing: _isEditing,
            icon: Icons.phone_outlined,
          ),
          const SizedBox(height: 16),

          _buildEditableField(
            label: 'Email',
            value: _userProfile.email,
            controller: _emailController,
            isEditing: _isEditing,
            icon: Icons.email_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required String value,
    required TextEditingController controller,
    required bool isEditing,
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
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), // THEME: Dynamic icon color
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), // THEME: Dynamic label color
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                if (isEditing)
                  TextField(
                    controller: controller,
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text color
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                    ),
                  )
                else
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text color
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          if (isEditing)
            Icon(
              Icons.edit_outlined,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), // THEME: Dynamic icon color
            ),
        ],
      ),
    );
  }


  Widget _buildActionButtons(ThemeProvider themeProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _toggleEdit,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeProvider.primaryColor, // THEME: Dynamic primary color
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                shadowColor: Colors.black.withOpacity(0.1),
              ),
              child: Text(
                _isEditing ? 'Save Changes' : 'Edit Profile',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: _logout,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626), // Keep red for logout
                side: const BorderSide(color: Color(0xFFDC2626)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Logout',
                style: GoogleFonts.poppins(
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

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.settings_outlined, color: Theme.of(context).primaryColor),
              title: Text('Settings', style: TextStyle(color: Theme.of(context).colorScheme.onBackground)),
              onTap: () {
                Navigator.pop(context);
                _navigateToSettings();
              },
            ),
            ListTile(
              leading: Icon(Icons.help_outline, color: Theme.of(context).primaryColor),
              title: Text('Help & Support', style: TextStyle(color: Theme.of(context).colorScheme.onBackground)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.privacy_tip_outlined, color: Theme.of(context).primaryColor),
              title: Text('Privacy Policy', style: TextStyle(color: Theme.of(context).colorScheme.onBackground)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
              title: Text('About', style: TextStyle(color: Theme.of(context).colorScheme.onBackground)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class UserProfile {
  String name;
  String username;
  String major;
  String age;
  String rollNumber;
  String phoneNumber;
  String email;
  String semester;
  String cgpa;

  UserProfile({
    required this.name,
    required this.username,
    required this.major,
    required this.age,
    required this.rollNumber,
    required this.phoneNumber,
    required this.email,
    required this.semester,
    required this.cgpa,
  });
}

class AcademicRecordsScreen extends StatelessWidget {
  const AcademicRecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background, // THEME: Dynamic background
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor, // THEME: Dynamic app bar
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onBackground), // THEME: Dynamic icon color
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Academic Records',
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text color
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
              'Complete academic records and transcripts would be displayed here.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), // THEME: Dynamic text color
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}