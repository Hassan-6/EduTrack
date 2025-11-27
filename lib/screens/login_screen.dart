import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/email_history_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // Email autocomplete
  List<String> _emailSuggestions = [];
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
    if (mounted) {
      setState(() {
        _emailSuggestions = emails;
      });
    }
  }

  void _onEmailChanged() {
    _updateEmailSuggestions();
  }

  void _updateEmailSuggestions() async {
    if (_isSelectingSuggestion) return;
    
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

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _removeOverlay();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    // Save email to history on login
    final email = _emailController.text.trim();
    if (email.isNotEmpty) {
      await EmailHistoryService.saveEmail(email);
    }
    
    // For now, hardcoded to navigate to main menu
    // Later you'll add Firebase authentication here
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/main_menu');
    }
  }

  void _navigateToRegistration() {
    Navigator.pushNamed(context, '/registration');
  }

  void _navigateToInstructorLogin() {
    Navigator.pushReplacementNamed(context, '/ins_menu');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard and overlay when tapping outside
        FocusScope.of(context).unfocus();
        _removeOverlay();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
              children: [
                const SizedBox(height: 75),
                
                // Logo Section
                _buildLogoSection(),
                
                const SizedBox(height: 40),
                
                // Login Title
                _buildLoginTitle(),
                
                const SizedBox(height: 60),
                
                // Input Fields
                _buildInputFields(),
                
                const SizedBox(height: 40),
                
                // Action Buttons
                _buildActionButtons(),
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return SizedBox(
      height: 258,
      child: Stack(
        children: [
          // Logo Container
          Positioned(
            left: 42,
            top: 55,
            child: Container(
              width: 149,
              height: 149,
              decoration: BoxDecoration(
                color: const Color(0xFF4F94CD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Image.network(
                  'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0SCOMduDvxzkW25UhUo3%2F526c0a1f-c482-4e62-94cc-3ba62b810687.png',
                  width: 84,
                  height: 59,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          
          // App Title
          Positioned(
            left: 212,
            top: 115,
            child: Text(
              'EduTrack',
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 32,
                fontWeight: FontWeight.w600,
                height: 0.9,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginTitle() {
    return Text(
      'Login',
      style: GoogleFonts.inter(
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
    );
  }

  Widget _buildInputFields() {
    return Column(
      children: [
        // Email Field
        CompositedTransformTarget(
          link: _layerLink,
          child: Container(
            width: 329,
            height: 51,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: const DecorationImage(
                image: NetworkImage(
                  'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0SCOMduDvxzkW25UhUo3%2F3f283dc3-a9fa-478d-8148-572529689792.png',
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: TextField(
              controller: _emailController,
              onTap: () {
                if (_emailSuggestions.isNotEmpty) {
                  _showOverlay();
                }
              },
              onChanged: (value) {
                // Trigger suggestions update on every character change
                _updateEmailSuggestions();
              },
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                hintText: 'E-mail',
                hintStyle: GoogleFonts.inter(
                  color: Colors.black.withOpacity(0.3),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.8,
                ),
              ),
              style: GoogleFonts.inter(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 15),
        
        // Password Field
        Container(
          width: 329,
          height: 51,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: const DecorationImage(
              image: NetworkImage(
                'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0SCOMduDvxzkW25UhUo3%2Ffddc9d63-47d0-4a37-8d7c-5dc684dd9429.png',
              ),
              fit: BoxFit.cover,
            ),
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              hintText: 'Password',
              hintStyle: GoogleFonts.inter(
                color: Colors.black.withOpacity(0.3),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.8,
              ),
            ),
            style: GoogleFonts.inter(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Login Button
        SizedBox(
          width: 164,
          height: 40,
          child: ElevatedButton(
            onPressed: _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F94CD),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'Login',
              style: GoogleFonts.inter(
                color: const Color(0xFFFFFEFE),
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 27),
        
        // Create Account Button
        SizedBox(
          width: 164,
          height: 40,
          child: ElevatedButton(
            onPressed: _navigateToRegistration,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F94CD),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'Create Account',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFFFFFEFE),
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 23),
        
        // Instructor Login Button
        SizedBox(
          width: 164,
          height: 40,
          child: ElevatedButton(
            onPressed: _navigateToInstructorLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F94CD),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'Ins. Login',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFFFFFEFE),
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}