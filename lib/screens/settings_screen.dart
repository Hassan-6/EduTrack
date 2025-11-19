// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedTheme = 'System';
  String _selectedReminderFrequency = 'Daily';
  bool _notificationsEnabled = true;
  bool _cameraPermissionsEnabled = true;
  bool _calendarSyncEnabled = false;
  double _fontSizeValue = 0.5;

  final List<String> _themeOptions = ['Light', 'Dark', 'System'];
  final List<String> _reminderOptions = ['Daily', 'Weekly', 'Monthly'];

  // Available accent colors
  final List<Color> _accentColors = [
    const Color(0xFF4E9FEC), // Blue
    const Color(0xFF5CD6C0), // Teal
    const Color(0xFF9C27B0), // Purple
    const Color(0xFFF44336), // Red
    const Color(0xFFFF9800), // Orange
    const Color(0xFF4CAF50), // Green
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
              ),
              
              // Preview Gradient
              _buildSettingsRow(
                icon: Icons.gradient,
                iconColor: Theme.of(context).primaryColor.withOpacity(0.1),
                title: 'Gradient Preview',
                trailing: Container(
                  width: 80,
                  height: 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: themeProvider.gradient,
                  ),
                ),
              ),
              
              // Font Size
              _buildSettingsRow(
                icon: Icons.text_fields,
                iconColor: Theme.of(context).primaryColor.withOpacity(0.1),
                title: 'Font Size',
                trailing: _buildFontSizeSlider(),
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
              
              // Camera Permissions
              _buildSettingsRow(
                icon: Icons.camera_alt_outlined,
                iconColor: Theme.of(context).primaryColor.withOpacity(0.1),
                title: 'Camera Permissions',
                trailing: _buildToggleSwitch(
                  value: _cameraPermissionsEnabled,
                  onChanged: (bool value) {
                    setState(() {
                      _cameraPermissionsEnabled = value;
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
              _buildSettingsRow(
                icon: Icons.lock_outline,
                iconColor: Theme.of(context).primaryColor.withOpacity(0.1),
                title: 'Change Password',
                trailing: _buildNavigationArrow(),
              ),
              
              // Delete Account
              _buildSettingsRow(
                icon: Icons.delete_outline,
                iconColor: const Color(0xFFFEF2F2),
                title: 'Delete Account',
                titleColor: const Color(0xFFEF4444),
                trailing: _buildNavigationArrow(),
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
    Color? titleColor, // Make it nullable by adding ?
  }) {
    return Container(
      height: 65,
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
                color: titleColor ?? Theme.of(context).colorScheme.onBackground, // Use null-aware operator
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
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF374151)
            : const Color(0xFFF9FAFB),
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
      width: 150,
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _accentColors.length,
        itemBuilder: (context, index) {
          final color = _accentColors[index];
          return GestureDetector(
            onTap: () => onColorSelected(color),
            child: Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: selectedColor == color 
                      ? Colors.white 
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

  Widget _buildFontSizeSlider() {
    return SizedBox(
      width: 98,
      height: 20,
      child: Stack(
        children: [
          // Small A
          Positioned(
            left: -1,
            top: 1,
            child: Text(
              'A',
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ),
          
          // Slider Track
          Positioned(
            left: 16,
            top: 8,
            child: Container(
              width: 64,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Stack(
                children: [
                  // Slider Thumb
                  Positioned(
                    left: _fontSizeValue * 32,
                    top: -4,
                    child: GestureDetector(
                      onHorizontalDragUpdate: (details) {
                        setState(() {
                          _fontSizeValue = (_fontSizeValue + details.delta.dx / 64).clamp(0.0, 1.0);
                        });
                      },
                      child: Container(
                        width: 15,
                        height: 15,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Large A
          Positioned(
            left: 87,
            top: -1,
            child: Text(
              'A',
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
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