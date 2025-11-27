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
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
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