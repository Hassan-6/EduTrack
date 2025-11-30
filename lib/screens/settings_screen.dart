import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme_provider.dart';
import '../services/firebase_service.dart';
import '../services/calendar_sync_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedTheme = 'System';
  String _selectedReminderFrequency = '1 Day';
  bool _notificationsEnabled = true;
  bool _calendarSyncEnabled = false;

  final List<String> _themeOptions = ['Light', 'Dark', 'System'];
  final List<String> _reminderOptions = ['1 Hour', '4 Hours', '8 Hours', '1 Day', '3 Days', '5 Days', '7 Days'];

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
    _loadPreferences();
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

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedReminderFrequency = prefs.getString('reminderFrequency') ?? '1 Day';
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _calendarSyncEnabled = prefs.getBool('calendarSyncEnabled') ?? false;
    });
  }

  Future<void> _saveReminderFrequency(String frequency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reminderFrequency', frequency);
  }

  Future<void> _saveNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', enabled);
  }

  Future<void> _saveCalendarSyncEnabled(bool enabled) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).primaryColor,
          ),
        ),
      ),
    );

    try {
      // Toggle calendar sync service
      await CalendarSyncService().toggleSync(enabled);
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled
                  ? 'Calendar sync enabled. Events will be synced to your device calendar.'
                  : 'Calendar sync disabled. Synced events have been removed.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Revert the toggle on error
        setState(() {
          _calendarSyncEnabled = !enabled;
        });
      }
    }
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

  Future<void> _showPasswordResetDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No user logged in'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Capture theme values
    final primaryColor = Theme.of(context).primaryColor;
    final cardColor = Theme.of(context).cardColor;
    final onBackgroundColor = Theme.of(context).colorScheme.onBackground;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cardColor,
        title: Text(
          'Reset Password',
          style: GoogleFonts.poppins(
            color: onBackgroundColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A password reset link will be sent to:',
              style: GoogleFonts.inter(
                color: onSurfaceColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user.email!,
              style: GoogleFonts.inter(
                color: primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Click the link in the email to set a new password.',
              style: GoogleFonts.inter(
                color: onSurfaceColor.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(color: onSurfaceColor.withOpacity(0.7)),
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(
                  email: user.email!,
                );
                
                Navigator.pop(dialogContext);
                
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text('Password reset email sent to ${user.email}'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 4),
                  ),
                );
              } on FirebaseAuthException catch (e) {
                String errorMessage = 'Failed to send reset email';
                
                if (e.code == 'user-not-found') {
                  errorMessage = 'No user found with this email';
                } else if (e.code == 'invalid-email') {
                  errorMessage = 'Invalid email address';
                } else if (e.code == 'too-many-requests') {
                  errorMessage = 'Too many requests. Please try again later.';
                }
                
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text(errorMessage),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 4),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            },
            child: Text(
              'Send Reset Link',
              style: TextStyle(color: primaryColor),
            ),
          ),
        ],
      ),
    );
  }



  Future<void> _showDeleteAccountDialog() async {
    final TextEditingController passwordController = TextEditingController();
    bool obscurePassword = true;

    // Capture all theme values before showing dialog
    final cardColor = Theme.of(context).cardColor;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final onBackgroundColor = Theme.of(context).colorScheme.onBackground;
    final dividerColor = Theme.of(context).dividerColor;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setStateDialog) => AlertDialog(
          backgroundColor: cardColor,
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
                    color: onSurfaceColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Please enter your password to confirm:',
                  style: GoogleFonts.inter(
                    color: onSurfaceColor.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  style: TextStyle(color: onBackgroundColor),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: onSurfaceColor.withOpacity(0.7)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: dividerColor),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFEF4444)),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: onSurfaceColor.withOpacity(0.7),
                      ),
                      onPressed: () {
                        setStateDialog(() {
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
              onPressed: () {
                passwordController.dispose();
                Navigator.pop(dialogContext);
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: onSurfaceColor.withOpacity(0.7)),
              ),
            ),
            TextButton(
              onPressed: () async {
                if (passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
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

                  // Try to sign in first to verify credentials
                  await FirebaseAuth.instance.signInWithEmailAndPassword(
                    email: user.email!,
                    password: passwordController.text.trim(),
                  );

                  // Delete user data from Firestore
                  await FirebaseService.deleteUserData(user.uid);

                  // Delete authentication account
                  await user.delete();

                  // Dispose controller
                  passwordController.dispose();

                  // Navigate to registration screen
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
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
                  
                  if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
                    errorMessage = 'Incorrect password';
                  } else if (e.code == 'requires-recent-login') {
                    errorMessage = 'Please log out and log in again before deleting account';
                  } else if (e.code == 'user-not-found') {
                    errorMessage = 'User account not found';
                  } else if (e.code == 'too-many-requests') {
                    errorMessage = 'Too many requests. Please try again later.';
                  }

                  if (context.mounted) {
                    Navigator.pop(dialogContext);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(errorMessage),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(dialogContext);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 4),
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
                    _saveNotificationsEnabled(value);
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
                    _saveCalendarSyncEnabled(value);
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
                    _saveReminderFrequency(newValue!);
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
              // Change Password (via Reset Link)
              GestureDetector(
                onTap: _showPasswordResetDialog,
                child: _buildSettingsRow(
                  icon: Icons.lock_outline,
                  iconColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  title: 'Reset Password',
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
