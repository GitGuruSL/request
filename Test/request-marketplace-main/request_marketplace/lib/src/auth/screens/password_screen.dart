import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:request_marketplace/src/navigation/main_navigation_screen.dart';
import 'package:request_marketplace/src/services/auth_service.dart';
import 'package:request_marketplace/src/theme/app_theme.dart';

class PasswordScreen extends StatefulWidget {
  final String email;
  const PasswordScreen({super.key, required this.email});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_passwordController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter your password');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    print("=== PASSWORD SCREEN LOGIN START ===");
    print("Email: ${widget.email}");
    print("Password length: ${_passwordController.text.trim().length}");
    
    try {
      final userCredential = await _authService.signInWithEmailAndPassword(
        email: widget.email,
        password: _passwordController.text.trim(),
      );

      print("Login result: ${userCredential != null ? 'SUCCESS' : 'NULL'}");
      
      if (userCredential != null) {
        print("Navigating to home screen...");
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
            (route) => false,
          );
        }
      } else {
        print("UserCredential is null, checking current user...");
        if (_authService.currentUser != null) {
          print("User is authenticated despite null return, navigating to home");
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
              (route) => false,
            );
          }
        } else {
          print("UserCredential is null and no current user - login failed");
          _showErrorSnackBar('Login failed. Unexpected error occurred.');
        }
      }
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException caught in password screen: ${e.code} - ${e.message}");
      
      String errorMessage;
      switch (e.code) {
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'user-not-found':
          errorMessage = 'No account found with this email.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed attempts. Please try again later.';
          break;
        case 'invalid-credential':
          errorMessage = 'Invalid email or password. Please try again.';
          break;
        default:
          errorMessage = 'Login failed: ${e.message}';
      }
      
      _showErrorSnackBar(errorMessage);
    } catch (e) {
      print("Unexpected error in password screen: $e");
      
      if (e.toString().contains("PigeonUserDetails") || e.toString().contains("List<Object?>")) {
        print("PigeonUserDetails error detected, checking Firebase auth state...");
        
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (_authService.currentUser != null) {
          print("User is authenticated despite error, navigating to home");
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
              (route) => false,
            );
          }
          return;
        }
      }
      
      _showErrorSnackBar('An unexpected error occurred. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleForgotPassword() async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: widget.email);
      _showSuccessSnackBar('Password reset email sent to ${widget.email}');
    } catch (e) {
      _showErrorSnackBar('Failed to send reset email. Please try again.');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // Header
              const Text(
                'Welcome back',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your password for\n${widget.email}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Password Input
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                ),
                child: TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade600),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  onSubmitted: (_) => _handleLogin(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _handleForgotPassword,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Login Button
              Container(
                width: double.infinity,
                height: 52,
                margin: const EdgeInsets.only(bottom: 32),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
