// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';
import '../services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedTheme = 'System';
  String _selectedReminderFrequency = 'Daily';
  bool _notificationsEnabled = true;
  bool _calendarSyncEnabled = false;

  final List<String> _themeOptions = ['Light', 'Dark', 'System'];
  final List<String> _reminderOptions = ['Hourly', '4 Hours', '8 Hours', 'Daily', '3 Days', '5 Days', 'Weekly'];

  // Available accent colors - expanded list with softer colors
  final List<Color> _accentColors = [
    const Color(0xFF6BA3F5), // Soft Blue
    const Color(0xFF7DD4C5), // Soft Teal
    const Color(0xFFB39DDB), // Soft Purple
    const Color(0xFFEF9A9A), // Soft Red
    const Color(0xFFFFB74D), // Soft Orange
    const Color(0xFF81C784), // Soft Green
    const Color(0xFFF48FB1), // Soft Pink
    const Color(0xFF4DD0E1), // Soft Cyan
    const Color(0xFFFFF176), // Soft Yellow
    const Color(0xFFA1887F), // Soft Brown
    const Color(0xFF90A4AE), // Soft Blue Grey
    const Color(0xFF7986CB), // Soft Indigo
    const Color(0xFFAED581), // Soft Light Green
    const Color(0xFFFF8A65), // Soft Deep Orange
    const Color(0xFF9575CD), // Soft Deep Purple
    const Color(0xFF4DB6AC), // Soft Teal Dark
  ];

  @override
  void initState() {
    super.initState();
    _initializeTheme();
  }

  void _initializeTheme() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    setState(() {
      _selectedTheme = themeProvider.themeMode == ThemeMode.light
          ? 'Light'
          : themeProvider.themeMode == ThemeMode.dark
              ? 'Dark'
              : 'System';
    });
  }

  // In your settings screen, just update the theme change handlers:
  void _handleThemeChange(String? newValue) {
    if (newValue == null) return;
    
    setState(() {
      _selectedTheme = newValue;
    });

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    switch (newValue) {
      case 'Light':
        themeProvider.setThemeMode(ThemeMode.light);
        break;
      case 'Dark':
        themeProvider.setThemeMode(ThemeMode.dark);
        break;
      case 'System':
        themeProvider.setThemeMode(ThemeMode.system);
        break;
    }
  }

  void _handlePrimaryColorChange(Color color) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.setPrimaryColor(color);
  }

  void _handleSecondaryColorChange(Color color) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.setSecondaryColor(color);
  }

  Future<void> _showChangePasswordDialog() async {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    bool obscureCurrentPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(
            'Change Password',
            style: GoogleFonts.poppins(
              color: Theme.of(context).colorScheme.onBackground,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: obscureCurrentPassword,
                  style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Theme.of(context).primaryColor),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureCurrentPassword ? Icons.visibility_off : Icons.visibility,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      onPressed: () {
                        setState(() {
                          obscureCurrentPassword = !obscureCurrentPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNewPassword,
                  style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Theme.of(context).primaryColor),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      onPressed: () {
                        setState(() {
                          obscureNewPassword = !obscureNewPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword,
                  style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Theme.of(context).primaryColor),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      onPressed: () {
                        setState(() {
                          obscureConfirmPassword = !obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
              ),
            ),
            TextButton(
              onPressed: () async {
                // Validate inputs
                if (currentPasswordController.text.isEmpty ||
                    newPasswordController.text.isEmpty ||
                    confirmPasswordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all fields'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (newPasswordController.text != confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('New passwords do not match'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (newPasswordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password must be at least 6 characters'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  // Get current user
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null || user.email == null) {
                    throw Exception('No user logged in');
                  }

                  // Reauthenticate user with current password
                  final credential = EmailAuthProvider.credential(
                    email: user.email!,
                    password: currentPasswordController.text,
                  );

                  await user.reauthenticateWithCredential(credential);

                  // Update password
                  await user.updatePassword(newPasswordController.text);

                  Navigator.pop(context);
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password changed successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } on FirebaseAuthException catch (e) {
                  String errorMessage = 'Failed to change password';
                  
                  if (e.code == 'wrong-password') {
                    errorMessage = 'Current password is incorrect';
                  } else if (e.code == 'weak-password') {
                    errorMessage = 'New password is too weak';
                  } else if (e.code == 'requires-recent-login') {
                    errorMessage = 'Please log out and log in again before changing password';
                  }

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(errorMessage),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text(
                'Change Password',
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ),
          ],
        ),
      ),
    );

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  Future<void> _showDeleteAccountDialog() async {
    final TextEditingController passwordController = TextEditingController();
    bool obscurePassword = true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Row(
            children: [
              const Icon(Icons.warning, color: Color(0xFFEF4444)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Delete Account',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFEF4444),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This action cannot be undone. All your data will be permanently deleted.',
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Please enter your password to confirm:',
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFEF4444)),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
              ),
            ),
            TextButton(
              onPressed: () async {
                if (passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter your password'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  // Get current user
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null || user.email == null) {
                    throw Exception('No user logged in');
                  }

                  // Reauthenticate user
                  final credential = EmailAuthProvider.credential(
                    email: user.email!,
                    password: passwordController.text,
                  );

                  await user.reauthenticateWithCredential(credential);

                  // Delete user data from Firestore
                  await FirebaseService.deleteUserData(user.uid);

                  // Delete authentication account
                  await user.delete();

                  // Navigate to registration screen
                  if (mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/registration',
                      (route) => false,
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Account deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } on FirebaseAuthException catch (e) {
                  String errorMessage = 'Failed to delete account';
                  
                  if (e.code == 'wrong-password') {
                    errorMessage = 'Incorrect password';
                  } else if (e.code == 'requires-recent-login') {
                    errorMessage = 'Please log out and log in again before deleting account';
                  }

                  Navigator.pop(context);
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(errorMessage),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  Navigator.pop(context);
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'Delete Account',
                style: TextStyle(color: Color(0xFFEF4444)),
              ),
            ),
          ],
        ),
      ),
    );

    passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              height: 72,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black.withOpacity(0.5)
                        : const Color(0x0C000000),
                    spreadRadius: 0,
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  )
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24),
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
                          Icon(
                            Icons.arrow_back_ios,
                            size: 11,
                            color: Theme.of(context).colorScheme.onBackground,
                          ),
                          const SizedBox(width: 9),
                          Text(
                            'Back',
                            style: GoogleFonts.inter(
                              color: Theme.of(context).colorScheme.onBackground,
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
                    'Settings',
                    style: GoogleFonts.inter(
                      color: Theme.of(context).colorScheme.onBackground,
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

            // Settings Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // General Settings Section
                    _buildGeneralSection(themeProvider),
                    const SizedBox(height: 24),

                    // Feature Settings Section
                    _buildFeatureSettingsSection(),
                    const SizedBox(height: 24),

                    // Account Section
                    _buildAccountSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSection(ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'General',
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // App Theme
              _buildSettingsRow(
                icon: Icons.palette_outlined,
                iconColor: Theme.of(context).primaryColor.withOpacity(0.1),
                title: 'App Theme',
                trailing: _buildDropdownButton(
                  value: _selectedTheme,
                  options: _themeOptions,
                  onChanged: _handleThemeChange,
                  width: 120,
                ),
              ),
              
              // Primary Accent Color
              _buildSettingsRow(
                icon: Icons.color_lens_outlined,
                iconColor: themeProvider.secondaryColor.withOpacity(0.1),
                title: 'Primary Color',
                trailing: _buildColorSelector(
                  selectedColor: themeProvider.primaryColor,
                  onColorSelected: _handlePrimaryColorChange,
                ),
                height: 80.0,
              ),
              
              // Secondary Accent Color
              _buildSettingsRow(
                icon: Icons.color_lens_outlined,
                iconColor: themeProvider.primaryColor.withOpacity(0.1),
                title: 'Secondary Color',
                trailing: _buildColorSelector(
                  selectedColor: themeProvider.secondaryColor,
                  onColorSelected: _handleSecondaryColorChange,
                ),
                height: 80.0,
              ),
              
              // Preview Gradient
              _buildSettingsRow(
                icon: Icons.gradient,
                iconColor: Theme.of(context).primaryColor.withOpacity(0.1),
                title: 'Gradient Preview',
                trailing: Container(
                  width: 120,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: themeProvider.gradient,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Feature Settings',
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Notifications
              _buildSettingsRow(
                icon: Icons.notifications_outlined,
                iconColor: Theme.of(context).primaryColor.withOpacity(0.1),
                title: 'Notifications',
                trailing: _buildToggleSwitch(
                  value: _notificationsEnabled,
                  onChanged: (bool value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                ),
              ),
              
              // Calendar Sync
              _buildSettingsRow(
                icon: Icons.calendar_today_outlined,
                iconColor: Theme.of(context).primaryColor.withOpacity(0.1),
                title: 'Calendar Sync',
                trailing: _buildToggleSwitch(
                  value: _calendarSyncEnabled,
                  onChanged: (bool value) {
                    setState(() {
                      _calendarSyncEnabled = value;
                    });
                  },
                ),
              ),
              
              // To-Do Reminders
              _buildSettingsRow(
                icon: Icons.alarm_outlined,
                iconColor: Theme.of(context).primaryColor.withOpacity(0.1),
                title: 'To-Do Reminders',
                trailing: _buildDropdownButton(
                  value: _selectedReminderFrequency,
                  options: _reminderOptions,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedReminderFrequency = newValue!;
                    });
                  },
                  width: 100,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account',
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Change Password
              GestureDetector(
                onTap: _showChangePasswordDialog,
                child: _buildSettingsRow(
                  icon: Icons.lock_outline,
                  iconColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  title: 'Change Password',
                  trailing: _buildNavigationArrow(),
                ),
              ),
              
              // Delete Account
              GestureDetector(
                onTap: _showDeleteAccountDialog,
                child: _buildSettingsRow(
                  icon: Icons.delete_outline,
                  iconColor: const Color(0xFFFEF2F2),
                  title: 'Delete Account',
                  titleColor: const Color(0xFFEF4444),
                  trailing: _buildNavigationArrow(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget trailing,
    Color? titleColor,
    double height = 65.0, // Make height configurable
  }) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 18,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Title
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                color: titleColor ?? Theme.of(context).colorScheme.onBackground,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Trailing Widget
          trailing,
        ],
      ),
    );
  }

  Widget _buildDropdownButton({
    required String value,
    required List<String> options,
    required Function(String?) onChanged,
    double width = 120,
  }) {
    return Container(
      width: width,
      height: 29,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(
            Icons.arrow_drop_down,
            color: Theme.of(context).colorScheme.onSurface,
            size: 20,
          ),
          items: options.map((String option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(
                option,
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildColorSelector({
    required Color selectedColor,
    required Function(Color) onColorSelected,
  }) {
    return SizedBox(
      width: 200,
      height: 60,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemCount: _accentColors.length,
        itemBuilder: (context, index) {
          final color = _accentColors[index];
          return GestureDetector(
            onTap: () => onColorSelected(color),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: selectedColor == color 
                      ? Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black
                      : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }



  Widget _buildToggleSwitch({
    required bool value,
    required Function(bool) onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 44,
        height: 24,
        decoration: BoxDecoration(
          color: value ? Theme.of(context).primaryColor : Theme.of(context).dividerColor,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(9999),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationArrow() {
    return Icon(
      Icons.arrow_forward_ios,
      size: 12,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
    );
  }
}