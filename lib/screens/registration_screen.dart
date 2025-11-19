import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/route_manager.dart';
import '../utils/theme_provider.dart';
import '../services/auth_provider.dart';
import 'forgot_password_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _isInstructor = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
      _passwordController.clear();
      _confirmPasswordController.clear();
      if (_isLogin) {
        _nameController.clear();
      }
    });
  }

  void _toggleUserType() {
    setState(() {
      _isInstructor = !_isInstructor;
    });
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  void _skipLogin() {
    RouteManager.setUserType('student');
    Navigator.pushReplacementNamed(context, '/main_menu');
  }

  void _skipInstructorLogin() {
    RouteManager.setUserType('instructor');
    Navigator.pushReplacementNamed(context, '/ins_main_menu');
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    if (_isLogin) {
      _login();
    } else {
      _register();
    }
  }

  void _login() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text,
        _isInstructor,
      );

      if (success) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_isInstructor ? 'Instructor' : 'Student'} login successful!'),
            backgroundColor: Colors.green.shade600,
          ),
        );

        RouteManager.setUserType(_isInstructor ? 'instructor' : 'student');

        if (_isInstructor) {
          Navigator.pushReplacementNamed(context, '/ins_main_menu');
        } else {
          Navigator.pushReplacementNamed(context, '/main_menu');
        }
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login failed. Please check your credentials.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login error: ${e.toString()}'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  void _register() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.signUp(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
        _isInstructor,
      );

      if (success) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_isInstructor ? 'Instructor' : 'Student'} registration successful!'),
            backgroundColor: Colors.green.shade600,
          ),
        );

        RouteManager.setUserType(_isInstructor ? 'instructor' : 'student');

        setState(() {
          _isLogin = true;
        });
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration error: ${e.toString()}'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (!_isLogin && (value == null || value.isEmpty)) {
      return 'Please enter your full name';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background, // THEME: Dynamic background
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildHeaderSection(themeProvider),
                const SizedBox(height: 40),

                Text(
                  _isLogin ? 'Welcome Back!' : 'Create Account',
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin 
                      ? 'Sign in to continue your ${_isInstructor ? 'teaching' : 'learning'} journey'
                      : 'Join EduTrack as ${_isInstructor ? 'an instructor' : 'a student'}',
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onSurface, // THEME: Dynamic text
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                _buildUserTypeToggle(themeProvider),
                const SizedBox(height: 16),

                _buildFormFields(),
                const SizedBox(height: 24),

                _buildActionButtons(themeProvider),
                const SizedBox(height: 24),

                _buildSkipLoginButtons(themeProvider),
                const SizedBox(height: 16),

                _buildAuthModeSwitch(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeToggle(ThemeProvider themeProvider) {
    return Container(
      width: 280,
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface, // THEME: Dynamic background
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_isInstructor) _toggleUserType();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: !_isInstructor ? themeProvider.primaryColor : Colors.transparent, // THEME: Dynamic color
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Student',
                    style: GoogleFonts.inter(
                      color: !_isInstructor ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.6), // THEME: Dynamic text
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!_isInstructor) _toggleUserType();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _isInstructor ? themeProvider.primaryColor : Colors.transparent, // THEME: Dynamic color
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Instructor',
                    style: GoogleFonts.inter(
                      color: _isInstructor ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.6), // THEME: Dynamic text
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(ThemeProvider themeProvider) {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            themeProvider.primaryColor.withOpacity(0.1), // THEME: Dynamic gradient
            Colors.transparent,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: themeProvider.primaryColor, // THEME: Dynamic color
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: themeProvider.primaryColor.withOpacity(0.3), // THEME: Dynamic shadow
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.school,
                    size: 50,
                    color: Theme.of(context).colorScheme.onPrimary, // THEME: Dynamic icon
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'EduTrack',
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your Academic Companion',
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onSurface, // THEME: Dynamic text
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          if (!_isLogin) ...[
            TextFormField(
              controller: _nameController,
              validator: _validateName,
              decoration: InputDecoration(
                labelText: 'Full Name',
                labelStyle: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onSurface, // THEME: Dynamic text
                  fontWeight: FontWeight.w500,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor), // THEME: Dynamic border
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2), // THEME: Dynamic border
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface, // THEME: Dynamic background
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
              ),
            ),
            const SizedBox(height: 16),
          ],

          TextFormField(
            controller: _emailController,
            validator: _validateEmail,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email Address',
              labelStyle: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurface, // THEME: Dynamic text
                fontWeight: FontWeight.w500,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).dividerColor), // THEME: Dynamic border
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2), // THEME: Dynamic border
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface, // THEME: Dynamic background
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _passwordController,
            validator: _validatePassword,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              labelStyle: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurface, // THEME: Dynamic text
                fontWeight: FontWeight.w500,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).dividerColor), // THEME: Dynamic border
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2), // THEME: Dynamic border
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface, // THEME: Dynamic background
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              suffixIcon: IconButton(
                onPressed: _togglePasswordVisibility,
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), // THEME: Dynamic icon
                ),
              ),
            ),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
            ),
          ),
          const SizedBox(height: 16),

          if (!_isLogin) ...[
            TextFormField(
              controller: _confirmPasswordController,
              validator: _validateConfirmPassword,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                labelStyle: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onSurface, // THEME: Dynamic text
                  fontWeight: FontWeight.w500,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor), // THEME: Dynamic border
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2), // THEME: Dynamic border
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface, // THEME: Dynamic background
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                suffixIcon: IconButton(
                  onPressed: _toggleConfirmPasswordVisibility,
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), // THEME: Dynamic icon
                  ),
                ),
              ),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onBackground, // THEME: Dynamic text
              ),
            ),
            const SizedBox(height: 8),
          ],

          if (_isLogin) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ForgotPasswordScreen(),
                    ),
                  );
                },
                child: Text(
                  'Forgot Password?',
                  style: GoogleFonts.inter(
                    color: Theme.of(context).primaryColor, // THEME: Dynamic text
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor, // THEME: Dynamic button
                foregroundColor: Theme.of(context).colorScheme.onPrimary, // THEME: Dynamic text
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                shadowColor: Theme.of(context).primaryColor.withOpacity(0.3), // THEME: Dynamic shadow
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary), // THEME: Dynamic progress
                      ),
                    )
                  : Text(
                      _isLogin ? 'Sign In' : 'Create Account',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Divider(color: Theme.of(context).dividerColor), // THEME: Dynamic divider
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Or continue with',
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onSurface, // THEME: Dynamic text
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                child: Divider(color: Theme.of(context).dividerColor), // THEME: Dynamic divider
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialButton(
                icon: Icons.g_mobiledata,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Google sign in would go here'),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              _buildSocialButton(
                icon: Icons.facebook,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Facebook sign in would go here'),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkipLoginButtons(ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: _skipLogin,
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor, // THEME: Dynamic text
                side: BorderSide(color: Theme.of(context).primaryColor), // THEME: Dynamic border
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.transparent,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school, size: 18, color: Theme.of(context).primaryColor), // THEME: Dynamic icon
                  const SizedBox(width: 8),
                  Text(
                    'Skip to Student App',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: _skipInstructorLogin,
              style: OutlinedButton.styleFrom(
                foregroundColor: themeProvider.secondaryColor, // THEME: Dynamic text
                side: BorderSide(color: themeProvider.secondaryColor), // THEME: Dynamic border
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.transparent,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person, size: 18, color: themeProvider.secondaryColor), // THEME: Dynamic icon
                  const SizedBox(width: 8),
                  Text(
                    'Skip to Instructor App',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // THEME: Dynamic card
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor), // THEME: Dynamic border
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.black.withOpacity(0.3) 
                : Colors.grey.shade200, // THEME: Adaptive shadow
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 24,
          color: Theme.of(context).colorScheme.onSurface, // THEME: Dynamic icon
        ),
      ),
    );
  }

  Widget _buildAuthModeSwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin ? "Don't have an account?" : 'Already have an account?',
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurface, // THEME: Dynamic text
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _toggleAuthMode,
          child: Text(
            _isLogin ? 'Sign Up' : 'Sign In',
            style: GoogleFonts.inter(
              color: Theme.of(context).primaryColor, // THEME: Dynamic text
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}