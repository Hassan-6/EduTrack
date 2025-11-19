import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _login() {
    // For now, hardcoded to navigate to main menu
    // Later you'll add Firebase authentication here
    Navigator.pushReplacementNamed(context, '/main_menu');
  }

  void _navigateToRegistration() {
    Navigator.pushNamed(context, '/registration');
  }

  void _navigateToInstructorLogin() {
    Navigator.pushReplacementNamed(context, '/ins_menu');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                color: const Color(0xFF1F2937),
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
        Container(
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