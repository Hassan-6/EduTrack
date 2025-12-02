// lib/utils/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Color _primaryColor = const Color(0xFF6BA3F5); // Softer Blue
  Color _secondaryColor = const Color(0xFF7DD4C5); // Softer Teal
  
  static const String _themeModeKey = 'theme_mode';
  static const String _primaryColorKey = 'primary_color';
  static const String _secondaryColorKey = 'secondary_color';

  ThemeMode get themeMode => _themeMode;
  Color get primaryColor => _primaryColor;
  Color get secondaryColor => _secondaryColor;
  
  ThemeProvider() {
    _loadThemeSettings();
  }
  
  // Load theme settings from SharedPreferences
  Future<void> _loadThemeSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load theme mode
      final themeModeString = prefs.getString(_themeModeKey);
      if (themeModeString != null) {
        _themeMode = ThemeMode.values.firstWhere(
          (mode) => mode.toString() == themeModeString,
          orElse: () => ThemeMode.system,
        );
      }
      
      // Load primary color
      final primaryColorValue = prefs.getInt(_primaryColorKey);
      if (primaryColorValue != null) {
        _primaryColor = Color(primaryColorValue);
      }
      
      // Load secondary color
      final secondaryColorValue = prefs.getInt(_secondaryColorKey);
      if (secondaryColorValue != null) {
        _secondaryColor = Color(secondaryColorValue);
      }
      
      notifyListeners();
    } catch (e) {
      print('Error loading theme settings: $e');
    }
  }
  
  // Save theme mode to SharedPreferences
  Future<void> _saveThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, _themeMode.toString());
    } catch (e) {
      print('Error saving theme mode: $e');
    }
  }
  
  // Save primary color to SharedPreferences
  Future<void> _savePrimaryColor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_primaryColorKey, _primaryColor.value);
    } catch (e) {
      print('Error saving primary color: $e');
    }
  }
  
  // Save secondary color to SharedPreferences
  Future<void> _saveSecondaryColor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_secondaryColorKey, _secondaryColor.value);
    } catch (e) {
      print('Error saving secondary color: $e');
    }
  }
  
  // Proper way to check if dark mode is active (accounts for system theme)
  bool isDarkMode(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _saveThemeMode();
    notifyListeners();
  }

  void setPrimaryColor(Color color) {
    _primaryColor = color;
    _savePrimaryColor();
    notifyListeners();
  }

  void setSecondaryColor(Color color) {
    _secondaryColor = color;
    _saveSecondaryColor();
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _saveThemeMode();
    notifyListeners();
  }

  LinearGradient get gradient => LinearGradient(
    colors: [_primaryColor, _secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}