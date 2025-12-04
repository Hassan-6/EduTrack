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
  final TextEditingController _departmentController = TextEditingController(); // For instructors

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
            profileIconIndex: profileData?['profileIconIndex'] ?? 0,
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
    _departmentController.text = _userProfile.major; // Department stored in major field
  }

  String _getSemesterValue(String currentValue) {
    // List of valid semester values
    const validSemesters = [
      '1st Semester',
      '2nd Semester',
      '3rd Semester',
      '4th Semester',
      '5th Semester',
      '6th Semester',
      '7th Semester',
      '8th Semester',
    ];
    
    // If current value is in the list, return it
    if (validSemesters.contains(currentValue)) {
      return currentValue;
    }
    
    // Default to 1st Semester if value is invalid or not set
    return '1st Semester';
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
      final isStudent = authProvider.userType == 'student';
      
      final updates = {
        'name': _nameController.text,
        'phoneNumber': _phoneController.text,
        'email': _emailController.text,
      };
      
      if (isStudent) {
        updates['rollNumber'] = _rollNumberController.text;
        updates['semester'] = _semesterController.text;
      } else {
        updates['major'] = _departmentController.text; // Department stored in major
      }
      
      await FirebaseService.updateUserProfile(currentUser.uid, updates);

      setState(() {
        _userProfile.name = _nameController.text;
        _userProfile.phoneNumber = _phoneController.text;
        _userProfile.email = _emailController.text;
        
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.userType == 'student') {
          _userProfile.rollNumber = _rollNumberController.text;
          _userProfile.semester = _semesterController.text;
        } else {
          _userProfile.major = _departmentController.text;
        }
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

  Future<void> _changeProfilePicture() async {
    final selectedIndex = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Choose Profile Icon',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: ProfileIcons.icons.length,
            itemBuilder: (context, index) {
              final isSelected = _userProfile.profileIconIndex == index;
              return InkWell(
                onTap: () => Navigator.pop(context, index),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).primaryColor.withOpacity(0.2)
                        : Theme.of(context).colorScheme.surface,
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).dividerColor,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        ProfileIcons.icons[index],
                        size: 32,
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ProfileIcons.iconNames[index],
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedIndex != null && selectedIndex != _userProfile.profileIconIndex) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUser = authProvider.currentUser;
        
        if (currentUser == null) return;

        // Update Firestore
        await FirebaseService.updateUserProfile(currentUser.uid, {
          'profileIconIndex': selectedIndex,
        });

        // Update local state
        setState(() {
          _userProfile.profileIconIndex = selectedIndex;
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile icon updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile icon: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Logout',
          style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              
              // Sign out from Firebase through AuthProvider
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.signOut();
              
              // Navigate to registration screen and clear all routes
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context, 
                  '/registration', 
                  (route) => false
                );
              }
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Color(0xFFDC2626)),
            ),
          ),
        ],
      ),
    );
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
        // Already on Profile
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
                  color: themeProvider.primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(60),
                  border: Border.all(
                    color: themeProvider.primaryColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  ProfileIcons.getIcon(_userProfile.profileIconIndex),
                  size: 60,
                  color: themeProvider.primaryColor,
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
                      Icons.edit,
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
              const SizedBox(height: 6),
              // Role descriptor and Roll Number/Department on separate lines
              Builder(builder: (ctx) {
                final authProvider = Provider.of<AuthProvider>(ctx, listen: false);
                final userType = authProvider.userType ?? '';
                
                return Column(
                  children: [
                    // First line: Roll Number or Department
                    Text(
                      userType == 'instructor'
                          ? (_userProfile.major.isNotEmpty ? _userProfile.major : '')
                          : (_userProfile.rollNumber.isNotEmpty ? _userProfile.rollNumber : ''),
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Second line: Student or Instructor
                    Text(
                      userType == 'instructor' ? 'Instructor' : 'Student',
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                );
              }),
        ],
      ),
    );
  }

  // Academic summary removed — semester is now part of Personal Details


  Widget _buildPersonalDetails() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isStudent = authProvider.userType == 'student';
    
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

          // Name (both)
          _buildEditableField(
            label: 'Full Name',
            value: _userProfile.name,
            controller: _nameController,
            isEditing: _isEditing,
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),

          // Student: Roll Number
          if (isStudent) ...[
            _buildEditableField(
              label: 'Roll Number',
              value: _userProfile.rollNumber,
              controller: _rollNumberController,
              isEditing: _isEditing,
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 16),
          ],

          // Student: Semester
          if (isStudent) ...[
            _buildEditableField(
              label: 'Semester',
              value: _userProfile.semester,
              controller: _semesterController,
              isEditing: _isEditing,
              icon: Icons.school_outlined,
              isSemester: true,
            ),
            const SizedBox(height: 16),
          ],

          // Instructor: Department
          if (!isStudent) ...[
            _buildEditableField(
              label: 'Department',
              value: _userProfile.major,
              controller: _departmentController,
              isEditing: _isEditing,
              icon: Icons.account_balance_outlined,
            ),
            const SizedBox(height: 16),
          ],

          // Phone Number (both)
          _buildEditableField(
            label: 'Phone Number',
            value: _userProfile.phoneNumber,
            controller: _phoneController,
            isEditing: _isEditing,
            icon: Icons.phone_outlined,
          ),
          const SizedBox(height: 16),

          // Email (both)
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
    bool isSemester = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.black.withOpacity(0.2) 
            : const Color(0xFFF9FAFB), // THEME: Adaptive background
        borderRadius: BorderRadius.circular(12),
        border: isEditing ? Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
          width: 1,
        ) : null,
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
                if (isEditing && isSemester)
                  // Dropdown for semester
                  DropdownButton<String>(
                    value: _getSemesterValue(controller.text),
                    isExpanded: true,
                    underline: const SizedBox(),
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    items: [
                      '1st Semester',
                      '2nd Semester',
                      '3rd Semester',
                      '4th Semester',
                      '5th Semester',
                      '6th Semester',
                      '7th Semester',
                      '8th Semester',
                    ].map((String semester) {
                      return DropdownMenuItem<String>(
                        value: semester,
                        child: Text(semester),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          controller.text = newValue;
                        });
                      }
                    },
                  )
                else if (isEditing)
                  // Editable text field
                  TextField(
                    controller: controller,
                    enabled: true,
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text color
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      hintText: 'Enter $label',
                      hintStyle: GoogleFonts.poppins(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (isEditing && !isSemester)
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
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: themeProvider.gradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _toggleEdit,
                child: Center(
                  child: Text(
                    _isEditing ? 'Save Changes' : 'Edit Profile',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
              leading: Icon(Icons.privacy_tip_outlined, color: Theme.of(context).primaryColor),
              title: Text('Privacy Policy', style: TextStyle(color: Theme.of(context).colorScheme.onBackground)),
              onTap: () {
                Navigator.pop(context);
                _navigateToPrivacyPolicy();
              },
            ),
            ListTile(
              leading: Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
              title: Text('About', style: TextStyle(color: Theme.of(context).colorScheme.onBackground)),
              onTap: () {
                Navigator.pop(context);
                _navigateToAbout();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPrivacyPolicy() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
    );
  }

  void _navigateToAbout() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AboutScreen()),
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
  int profileIconIndex; // Index of selected profile icon (0-11)

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
    this.profileIconIndex = 0, // Default to first icon
  });
}

// List of available profile icons
class ProfileIcons {
  static const List<IconData> icons = [
    Icons.person,
    Icons.account_circle,
    Icons.face,
    Icons.sentiment_satisfied_alt,
    Icons.mood,
    Icons.emoji_emotions,
    Icons.school,
    Icons.workspace_premium,
    Icons.stars,
    Icons.rocket_launch,
    Icons.lightbulb,
    Icons.auto_awesome,
  ];

  static const List<String> iconNames = [
    'Default',
    'Circle',
    'Face',
    'Happy',
    'Smile',
    'Emoji',
    'Graduate',
    'Premium',
    'Star',
    'Rocket',
    'Idea',
    'Sparkle',
  ];

  static IconData getIcon(int index) {
    if (index >= 0 && index < icons.length) {
      return icons[index];
    }
    return icons[0]; // Default
  }

  static String getIconName(int index) {
    if (index >= 0 && index < iconNames.length) {
      return iconNames[index];
    }
    return iconNames[0];
  }
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

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onBackground),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onBackground,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Last Updated
            Text(
              'Last updated: November 29, 2025',
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 20),
            
            // Introduction
            Text(
              'This Privacy Policy describes Our policies and procedures on the collection, use and disclosure of Your information when You use the Service and tells You about Your privacy rights and how the law protects You.',
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'We use Your Personal data to provide and improve the Service. By using the Service, You agree to the collection and use of information in accordance with this Privacy Policy.',
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),

            // Interpretation and Definitions
            _buildSectionTitle(context, 'Interpretation and Definitions'),
            const SizedBox(height: 12),
            _buildSubsectionTitle(context, 'Interpretation'),
            const SizedBox(height: 8),
            _buildParagraph(context, 'The words whose initial letters are capitalized have meanings defined under the following conditions. The following definitions shall have the same meaning regardless of whether they appear in singular or in plural.'),
            const SizedBox(height: 16),
            
            _buildSubsectionTitle(context, 'Definitions'),
            const SizedBox(height: 8),
            _buildParagraph(context, 'For the purposes of this Privacy Policy:'),
            const SizedBox(height: 12),
            _buildDefinition(context, 'Account', 'means a unique account created for You to access our Service or parts of our Service.'),
            _buildDefinition(context, 'Affiliate', 'means an entity that controls, is controlled by, or is under common control with a party, where "control" means ownership of 50% or more of the shares, equity interest or other securities entitled to vote for election of directors or other managing authority.'),
            _buildDefinition(context, 'Application', 'refers to EduTrack, the software program provided by the Company.'),
            _buildDefinition(context, 'Company', '(referred to as either "the Company", "We", "Us" or "Our" in this Agreement) refers to EduTrack.'),
            _buildDefinition(context, 'Country', 'refers to: Pakistan'),
            _buildDefinition(context, 'Device', 'means any device that can access the Service such as a computer, a cell phone or a digital tablet.'),
            _buildDefinition(context, 'Personal Data', 'is any information that relates to an identified or identifiable individual.'),
            _buildDefinition(context, 'Service', 'refers to the Application.'),
            _buildDefinition(context, 'Service Provider', 'means any natural or legal person who processes the data on behalf of the Company. It refers to third-party companies or individuals employed by the Company to facilitate the Service, to provide the Service on behalf of the Company, to perform services related to the Service or to assist the Company in analyzing how the Service is used.'),
            _buildDefinition(context, 'Usage Data', 'refers to data collected automatically, either generated by the use of the Service or from the Service infrastructure itself (for example, the duration of a page visit).'),
            _buildDefinition(context, 'You', 'means the individual accessing or using the Service, or the company, or other legal entity on behalf of which such individual is accessing or using the Service, as applicable.'),
            const SizedBox(height: 24),

            // Collecting and Using Your Personal Data
            _buildSectionTitle(context, 'Collecting and Using Your Personal Data'),
            const SizedBox(height: 12),
            _buildSubsectionTitle(context, 'Types of Data Collected'),
            const SizedBox(height: 12),
            
            Text(
              'Personal Data',
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildParagraph(context, 'While using Our Service, We may ask You to provide Us with certain personally identifiable information that can be used to contact or identify You. Personally identifiable information may include, but is not limited to:'),
            const SizedBox(height: 8),
            _buildBulletPoint(context, 'Email address'),
            _buildBulletPoint(context, 'First name and last name'),
            _buildBulletPoint(context, 'Phone number'),
            _buildBulletPoint(context, 'Usage Data'),
            const SizedBox(height: 16),

            Text(
              'Usage Data',
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildParagraph(context, 'Usage Data is collected automatically when using the Service.'),
            const SizedBox(height: 8),
            _buildParagraph(context, 'Usage Data may include information such as Your Device\'s Internet Protocol address (e.g. IP address), browser type, browser version, the pages of our Service that You visit, the time and date of Your visit, the time spent on those pages, unique device identifiers and other diagnostic data.'),
            const SizedBox(height: 8),
            _buildParagraph(context, 'When You access the Service by or through a mobile device, We may collect certain information automatically, including, but not limited to, the type of mobile device You use, Your mobile device\'s unique ID, the IP address of Your mobile device, Your mobile operating system, the type of mobile Internet browser You use, unique device identifiers and other diagnostic data.'),
            const SizedBox(height: 8),
            _buildParagraph(context, 'We may also collect information that Your browser sends whenever You visit Our Service or when You access the Service by or through a mobile device.'),
            const SizedBox(height: 16),

            Text(
              'Information Collected while Using the Application',
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildParagraph(context, 'While using Our Application, in order to provide features of Our Application, We may collect, with Your prior permission:'),
            const SizedBox(height: 8),
            _buildBulletPoint(context, 'Information regarding your location'),
            _buildBulletPoint(context, 'Pictures and other information from your Device\'s camera and photo library'),
            const SizedBox(height: 8),
            _buildParagraph(context, 'We use this information to provide features of Our Service, to improve and customize Our Service. The information may be uploaded to the Company\'s servers and/or a Service Provider\'s server or it may be simply stored on Your device.'),
            const SizedBox(height: 8),
            _buildParagraph(context, 'You can enable or disable access to this information at any time, through Your Device settings.'),
            const SizedBox(height: 24),

            // Use of Your Personal Data
            _buildSubsectionTitle(context, 'Use of Your Personal Data'),
            const SizedBox(height: 8),
            _buildParagraph(context, 'The Company may use Personal Data for the following purposes:'),
            const SizedBox(height: 8),
            _buildBulletPoint(context, 'To provide and maintain our Service, including to monitor the usage of our Service.'),
            _buildBulletPoint(context, 'To manage Your Account: to manage Your registration as a user of the Service. The Personal Data You provide can give You access to different functionalities of the Service that are available to You as a registered user.'),
            _buildBulletPoint(context, 'For the performance of a contract: the development, compliance and undertaking of the purchase contract for the products, items or services You have purchased or of any other contract with Us through the Service.'),
            _buildBulletPoint(context, 'To contact You: To contact You by email, telephone calls, SMS, or other equivalent forms of electronic communication, such as a mobile application\'s push notifications regarding updates or informative communications related to the functionalities, products or contracted services, including the security updates, when necessary or reasonable for their implementation.'),
            _buildBulletPoint(context, 'To provide You with news, special offers, and general information about other goods, services and events which We offer that are similar to those that you have already purchased or inquired about unless You have opted not to receive such information.'),
            _buildBulletPoint(context, 'To manage Your requests: To attend and manage Your requests to Us.'),
            _buildBulletPoint(context, 'For business transfers: We may use Your information to evaluate or conduct a merger, divestiture, restructuring, reorganization, dissolution, or other sale or transfer of some or all of Our assets, whether as a going concern or as part of bankruptcy, liquidation, or similar proceeding, in which Personal Data held by Us about our Service users is among the assets transferred.'),
            _buildBulletPoint(context, 'For other purposes: We may use Your information for other purposes, such as data analysis, identifying usage trends, determining the effectiveness of our promotional campaigns and to evaluate and improve our Service, products, services, marketing and your experience.'),
            const SizedBox(height: 12),
            _buildParagraph(context, 'We may share Your personal information in the following situations:'),
            const SizedBox(height: 8),
            _buildBulletPoint(context, 'With Service Providers: We may share Your personal information with Service Providers to monitor and analyze the use of our Service, to contact You.'),
            _buildBulletPoint(context, 'For business transfers: We may share or transfer Your personal information in connection with, or during negotiations of, any merger, sale of Company assets, financing, or acquisition of all or a portion of Our business to another company.'),
            _buildBulletPoint(context, 'With Affiliates: We may share Your information with Our affiliates, in which case we will require those affiliates to honor this Privacy Policy. Affiliates include Our parent company and any other subsidiaries, joint venture partners or other companies that We control or that are under common control with Us.'),
            _buildBulletPoint(context, 'With business partners: We may share Your information with Our business partners to offer You certain products, services or promotions.'),
            _buildBulletPoint(context, 'With other users: when You share personal information or otherwise interact in the public areas with other users, such information may be viewed by all users and may be publicly distributed outside.'),
            _buildBulletPoint(context, 'With Your consent: We may disclose Your personal information for any other purpose with Your consent.'),
            const SizedBox(height: 24),

            // Retention of Your Personal Data
            _buildSubsectionTitle(context, 'Retention of Your Personal Data'),
            const SizedBox(height: 8),
            _buildParagraph(context, 'The Company will retain Your Personal Data only for as long as is necessary for the purposes set out in this Privacy Policy. We will retain and use Your Personal Data to the extent necessary to comply with our legal obligations (for example, if we are required to retain your data to comply with applicable laws), resolve disputes, and enforce our legal agreements and policies.'),
            const SizedBox(height: 8),
            _buildParagraph(context, 'The Company will also retain Usage Data for internal analysis purposes. Usage Data is generally retained for a shorter period of time, except when this data is used to strengthen the security or to improve the functionality of Our Service, or We are legally obligated to retain this data for longer periods.'),
            const SizedBox(height: 24),

            // Transfer of Your Personal Data
            _buildSubsectionTitle(context, 'Transfer of Your Personal Data'),
            const SizedBox(height: 8),
            _buildParagraph(context, 'Your information, including Personal Data, is processed at the Company\'s operating offices and in any other places where the parties involved in the processing are located. It means that this information may be transferred to — and maintained on — computers located outside of Your state, province, country or other governmental jurisdiction where the data protection laws may differ from those from Your jurisdiction.'),
            const SizedBox(height: 8),
            _buildParagraph(context, 'Your consent to this Privacy Policy followed by Your submission of such information represents Your agreement to that transfer.'),
            const SizedBox(height: 8),
            _buildParagraph(context, 'The Company will take all steps reasonably necessary to ensure that Your data is treated securely and in accordance with this Privacy Policy and no transfer of Your Personal Data will take place to an organization or a country unless there are adequate controls in place including the security of Your data and other personal information.'),
            const SizedBox(height: 24),

            // Delete Your Personal Data
            _buildSubsectionTitle(context, 'Delete Your Personal Data'),
            const SizedBox(height: 8),
            _buildParagraph(context, 'You have the right to delete or request that We assist in deleting the Personal Data that We have collected about You.'),
            const SizedBox(height: 8),
            _buildParagraph(context, 'Our Service may give You the ability to delete certain information about You from within the Service.'),
            const SizedBox(height: 8),
            _buildParagraph(context, 'You may update, amend, or delete Your information at any time by signing in to Your Account, if you have one, and visiting the account settings section that allows you to manage Your personal information. You may also contact Us to request access to, correct, or delete any personal information that You have provided to Us.'),
            const SizedBox(height: 8),
            _buildParagraph(context, 'Please note, however, that We may need to retain certain information when we have a legal obligation or lawful basis to do so.'),
            const SizedBox(height: 24),

            // Disclosure of Your Personal Data
            _buildSectionTitle(context, 'Disclosure of Your Personal Data'),
            const SizedBox(height: 12),
            _buildSubsectionTitle(context, 'Business Transactions'),
            const SizedBox(height: 8),
            _buildParagraph(context, 'If the Company is involved in a merger, acquisition or asset sale, Your Personal Data may be transferred. We will provide notice before Your Personal Data is transferred and becomes subject to a different Privacy Policy.'),
            const SizedBox(height: 16),

            _buildSubsectionTitle(context, 'Law enforcement'),
            const SizedBox(height: 8),
            _buildParagraph(context, 'Under certain circumstances, the Company may be required to disclose Your Personal Data if required to do so by law or in response to valid requests by public authorities (e.g. a court or a government agency).'),
            const SizedBox(height: 16),

            _buildSubsectionTitle(context, 'Other legal requirements'),
            const SizedBox(height: 8),
            _buildParagraph(context, 'The Company may disclose Your Personal Data in the good faith belief that such action is necessary to:'),
            const SizedBox(height: 8),
            _buildBulletPoint(context, 'Comply with a legal obligation'),
            _buildBulletPoint(context, 'Protect and defend the rights or property of the Company'),
            _buildBulletPoint(context, 'Prevent or investigate possible wrongdoing in connection with the Service'),
            _buildBulletPoint(context, 'Protect the personal safety of Users of the Service or the public'),
            _buildBulletPoint(context, 'Protect against legal liability'),
            const SizedBox(height: 24),

            // Security of Your Personal Data
            _buildSectionTitle(context, 'Security of Your Personal Data'),
            const SizedBox(height: 8),
            _buildParagraph(context, 'The security of Your Personal Data is important to Us, but remember that no method of transmission over the Internet, or method of electronic storage is 100% secure. While We strive to use commercially reasonable means to protect Your Personal Data, We cannot guarantee its absolute security.'),
            const SizedBox(height: 24),

            // Children's Privacy
            _buildSectionTitle(context, 'Children\'s Privacy'),
            const SizedBox(height: 8),
            _buildParagraph(context, 'Our Service does not address anyone under the age of 13. We do not knowingly collect personally identifiable information from anyone under the age of 13. If You are a parent or guardian and You are aware that Your child has provided Us with Personal Data, please contact Us. If We become aware that We have collected Personal Data from anyone under the age of 13 without verification of parental consent, We take steps to remove that information from Our servers.'),
            const SizedBox(height: 8),
            _buildParagraph(context, 'If We need to rely on consent as a legal basis for processing Your information and Your country requires consent from a parent, We may require Your parent\'s consent before We collect and use that information.'),
            const SizedBox(height: 24),

            // Links to Other Websites
            _buildSectionTitle(context, 'Links to Other Websites'),
            const SizedBox(height: 8),
            _buildParagraph(context, 'Our Service may contain links to other websites that are not operated by Us. If You click on a third party link, You will be directed to that third party\'s site. We strongly advise You to review the Privacy Policy of every site You visit.'),
            const SizedBox(height: 8),
            _buildParagraph(context, 'We have no control over and assume no responsibility for the content, privacy policies or practices of any third party sites or services.'),
            const SizedBox(height: 24),

            // Changes to this Privacy Policy
            _buildSectionTitle(context, 'Changes to this Privacy Policy'),
            const SizedBox(height: 8),
            _buildParagraph(context, 'We may update Our Privacy Policy from time to time. We will notify You of any changes by posting the new Privacy Policy on this page.'),
            const SizedBox(height: 8),
            _buildParagraph(context, 'We will let You know via email and/or a prominent notice on Our Service, prior to the change becoming effective and update the "Last updated" date at the top of this Privacy Policy.'),
            const SizedBox(height: 8),
            _buildParagraph(context, 'You are advised to review this Privacy Policy periodically for any changes. Changes to this Privacy Policy are effective when they are posted on this page.'),
            const SizedBox(height: 24),

            // Contact Us
            _buildSectionTitle(context, 'Contact Us'),
            const SizedBox(height: 8),
            _buildParagraph(context, 'If you have any questions about this Privacy Policy, You can contact us:'),
            const SizedBox(height: 8),
            _buildBulletPoint(context, 'By email: oneebtariq@gmail.com'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Helper methods for Privacy Policy formatting
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: Theme.of(context).primaryColor,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildSubsectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildParagraph(BuildContext context, String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        fontSize: 14,
        height: 1.6,
      ),
    );
  }

  Widget _buildBulletPoint(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: 14,
              height: 1.6,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefinition(BuildContext context, String term, String definition) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 10),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$term ',
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.6,
              ),
            ),
            TextSpan(
              text: definition,
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onBackground),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'About',
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onBackground,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About EduTrack',
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.onBackground,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Version 1.0.0',
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'EduTrack is an educational platform designed to help students and instructors manage courses, assignments, and academic activities.',
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Additional information about the app, team, and features will be added here.',
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}