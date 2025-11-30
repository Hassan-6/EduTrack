import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/route_manager.dart';
import '../utils/theme_provider.dart';
import '../services/auth_provider.dart';
import '../services/email_history_service.dart';
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
  final TextEditingController _rollNumberController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  
  // Email autocomplete
  List<String> _emailSuggestions = [];
  bool _showEmailSuggestions = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isSelectingSuggestion = false;

  @override
  void initState() {
    super.initState();
    _loadEmailHistory();
    _emailController.addListener(_onEmailChanged);
  }

  Future<void> _loadEmailHistory() async {
    final emails = await EmailHistoryService.getEmailHistory();
    setState(() {
      _emailSuggestions = emails;
    });
  }

  void _onEmailChanged() {
    _updateEmailSuggestions();
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _removeOverlay();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _rollNumberController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
      _passwordController.clear();
      _confirmPasswordController.clear();
      if (_isLogin) {
        _nameController.clear();
        _rollNumberController.clear();
      } else {
        // Remove email suggestions when switching to signup mode
        _removeOverlay();
      }
    });
  }

  void _toggleUserType() {
    setState(() {
      _isInstructor = !_isInstructor;
    });
  }

  void _updateEmailSuggestions() async {
    if (_isSelectingSuggestion) return;
    
    // Only show email suggestions on login page, not on signup
    if (!_isLogin) {
      _removeOverlay();
      return;
    }
    
    final query = _emailController.text.trim();
    
    final suggestions = await EmailHistoryService.getSuggestions(query);
    if (suggestions.isNotEmpty && mounted) {
      setState(() {
        _emailSuggestions = suggestions;
      });
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          _removeOverlay();
        },
        child: Stack(
          children: [
            Positioned(
              width: MediaQuery.of(context).size.width - 48,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: const Offset(0, 60),
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade400, width: 1),
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _emailSuggestions.length,
                      itemBuilder: (context, index) {
                        final email = _emailSuggestions[index];
                        return InkWell(
                          onTap: () {
                            _isSelectingSuggestion = true;
                            _emailController.text = email;
                            _emailController.selection = TextSelection.fromPosition(
                              TextPosition(offset: email.length),
                            );
                            _removeOverlay();
                            FocusScope.of(context).unfocus();
                            Future.delayed(const Duration(milliseconds: 100), () {
                              _isSelectingSuggestion = false;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: index < _emailSuggestions.length - 1
                                    ? BorderSide(color: Colors.grey.shade200)
                                    : BorderSide.none,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.history, size: 20, color: Colors.grey.shade600),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    email,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
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
      final result = await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text,
        _isInstructor,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        // Save email to history on successful login
        await EmailHistoryService.saveEmail(_emailController.text.trim());
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_isInstructor ? 'Instructor' : 'Student'} login successful!'),
            backgroundColor: Colors.green.shade600,
          ),
        );

        RouteManager.setUserType(authProvider.userType ?? (_isInstructor ? 'instructor' : 'student'));

        // Route based on actual stored role
        if (authProvider.userType == 'instructor') {
          Navigator.pushReplacementNamed(context, '/ins_main_menu');
        } else {
          Navigator.pushReplacementNamed(context, '/main_menu');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error']?.contains('password') == true 
                ? 'Invalid password. Please try again.'
                : (result['error'] ?? 'Login failed. Please check your credentials.')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
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
        rollNumber: _isInstructor ? null : _rollNumberController.text.trim(),
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
    
    // Only validate password criteria during signup
    if (!_isLogin) {
      if (value.length < 6) {
        return 'Password must be at least 6 characters';
      }
      if (!value.contains(RegExp(r'[A-Z]'))) {
        return 'Password must contain at least one uppercase letter';
      }
      if (!value.contains(RegExp(r'[0-9]'))) {
        return 'Password must contain at least one number';
      }
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

  String? _validateRollNumber(String? value) {
    if (!_isLogin && !_isInstructor && (value == null || value.isEmpty)) {
      return 'Please enter your roll number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard and overlay when tapping outside
        FocusScope.of(context).unfocus();
        _removeOverlay();
      },
      child: Scaffold(
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

                  _buildAuthModeSwitch(),
                  const SizedBox(height: 20),
                ],
              ),
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
          if (!_isLogin && !_isInstructor) ...[
            TextFormField(
              controller: _rollNumberController,
              validator: _validateRollNumber,
              decoration: InputDecoration(
                labelText: 'Roll Number',
                labelStyle: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 16),
          ],

          CompositedTransformTarget(
            link: _layerLink,
            child: TextFormField(
              controller: _emailController,
              validator: _validateEmail,
              keyboardType: TextInputType.emailAddress,
              autofillHints: _isLogin ? [AutofillHints.email] : [],
              onTap: () {
                if (_isLogin && _emailSuggestions.isNotEmpty) {
                  _showOverlay();
                }
              },
              onChanged: (value) {
                // Only trigger suggestions update on login page
                if (_isLogin) {
                  _updateEmailSuggestions();
                }
              },
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
            // Password criteria tooltip for signup
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Password must be at least 6 characters, contain one uppercase letter and one number',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: _isLoading ? null : themeProvider.gradient,
              color: _isLoading ? Theme.of(context).disabledColor.withOpacity(0.3) : null,
              borderRadius: BorderRadius.circular(12),
              boxShadow: _isLoading ? null : [
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
                onTap: _isLoading ? null : _submitForm,
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _isLogin ? 'Sign In' : 'Create Account',
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
        ],
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