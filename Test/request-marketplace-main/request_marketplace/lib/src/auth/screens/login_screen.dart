import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:request_marketplace/src/auth/screens/otp_screen.dart';
import 'package:request_marketplace/src/auth/screens/password_screen.dart';
import 'package:request_marketplace/src/auth/screens/email_otp_verification_screen.dart';
import 'package:request_marketplace/src/navigation/main_navigation_screen.dart';
import 'package:request_marketplace/src/services/auth_service.dart';
import 'package:request_marketplace/src/services/email_otp_service.dart';

class LoginScreen extends StatefulWidget {
  final String countryCode;

  const LoginScreen({super.key, required this.countryCode});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final EmailOtpService _emailOtpService = EmailOtpService();
  bool _isEmail = false;
  final TextEditingController _controller = TextEditingController();
  String _phoneNumber = '';
  bool _isLoading = false;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize the phone number with the country code if coming from welcome screen
    if (widget.countryCode.isNotEmpty) {
      _isEmail = false;
    }
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _handleContinue() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final value = _isEmail ? _controller.text.trim().toLowerCase() : _phoneNumber;
      
      final userExists = await _authService.isUserExists(value);

      if (userExists) {
        if (_isEmail) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => PasswordScreen(email: value)),
          );
        } else {
          // Existing user with phone -> send OTP
          _authService.sendOtp(
            value: value,
            isEmail: false,
            codeSent: (verificationId, forceResendingToken) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OTPScreen(
                    verificationId: verificationId,
                    countryCode: widget.countryCode,
                  ),
                ),
              );
            },
            verificationFailed: (errorMessage) {
              // Handle SMS verification failure
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(errorMessage)),
                );
              }
            },
          );
        }
      } else {
        // New user
        if (_isEmail) {
          // Use our custom email OTP service for new users
          try {
            await _emailOtpService.sendEmailOtp(value);
            
            // Navigate to our custom email OTP verification screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EmailOtpVerificationScreen(
                  email: value,
                ),
              ),
            );
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to send OTP: $e')),
              );
            }
          }
        } else {
          // New user with phone -> send OTP
          _authService.sendOtp(
            value: value,
            isEmail: false,
            codeSent: (verificationId, forceResendingToken) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OTPScreen(
                    verificationId: verificationId,
                    isNewUser: true,
                    emailOrPhone: value,
                    isEmail: false,
                    countryCode: widget.countryCode,
                  ),
                ),
              );
            },
            verificationFailed: (errorMessage) {
              // Handle SMS verification failure
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(errorMessage)),
                );
              }
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleGoogleSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      // Use only the simplified Google Sign-In method
      final UserCredential? userCredential = await _authService.signInWithGoogle();
      
      if (userCredential != null) {
        // User exists, navigate to home
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    const MainNavigationScreen()),
            (route) => false,
          );
        }
      } else {
        // Wait a moment and check if user is actually authenticated
        await Future.delayed(const Duration(milliseconds: 300));
        
        if (_authService.currentUser != null) {
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
              (route) => false,
            );
          }
        } else {
          // Handle Google Sign-In failure
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Google Sign-In was cancelled.')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        // Check if this is the known type casting error but Firebase auth actually succeeded
        if (e.toString().contains("PigeonUserDetails") || e.toString().contains("List<Object?>")) {
          // Wait a moment for Firebase to update state
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Check if user is actually authenticated in Firebase
          if (_authService.currentUser != null) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
              (route) => false,
            );
            return;
          }
        }
        
        // Show appropriate error message
        String errorMessage = 'Google sign-in failed.';
        if (e.toString().contains("PigeonUserDetails") || e.toString().contains("List<Object?>")) {
          errorMessage = 'Google Sign-In completed but encountered a technical issue. Please try again or use email/phone login.';
        } else if (e.toString().contains("SIGN_IN_CANCELLED")) {
          errorMessage = 'Google Sign-In was cancelled.';
        } else if (e.toString().contains("ApiException: 10")) {
          errorMessage = 'Google Sign-In not available on this device. Please use email or phone login.';
        } else if (e.toString().contains("sign_in_failed")) {
          errorMessage = 'Google Sign-In service unavailable. Please try email or phone login.';
        } else if (e.toString().contains("network")) {
          errorMessage = 'Network error. Please check your connection and try again.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBFE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Color(0xFF1D1B20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              SizedBox(height: size.height * 0.02),
              
              // Header
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D1B20),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sign in to your account',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF49454F),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: size.height * 0.04),
              
              // Input method selector
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F2FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isEmail = true),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _isEmail ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(
                                    'assets/icons/email_icon.svg',
                                    width: 16,
                                    height: 16,
                                    colorFilter: ColorFilter.mode(
                                      _isEmail ? theme.colorScheme.primary : Colors.grey[600]!,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Email',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: _isEmail ? theme.colorScheme.primary : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isEmail = false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_isEmail ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: !_isEmail
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(
                                    'assets/icons/phone_icon.svg',
                                    width: 16,
                                    height: 16,
                                    colorFilter: ColorFilter.mode(
                                      !_isEmail ? theme.colorScheme.primary : Colors.grey[600]!,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Phone',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: !_isEmail ? theme.colorScheme.primary : Colors.grey[600],
                                    ),
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
              ),
              
              const SizedBox(height: 24),
              
              // Input field
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _isEmail
                        ? SizedBox(
                            height: 52,
                            child: TextFormField(
                              controller: _controller,
                              keyboardType: TextInputType.emailAddress,
                              textAlign: TextAlign.start,
                              style: const TextStyle(
                                color: Color(0xFF1D1B20),
                                fontSize: 16,
                                height: 1.2,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Enter your email',
                                hintStyle: TextStyle(
                                  color: Color(0xFF79747E),
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                isDense: false,
                              ),
                            ),
                          )
                        : SizedBox(
                            height: 52, // Constrain the height to match the email field
                            child: IntlPhoneField(
                              style: const TextStyle(
                                color: Color(0xFF1D1B20),
                                fontSize: 16,
                                height: 1.2, // Better line height for proper centering
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), // Match email field padding
                                isDense: false,
                                alignLabelWithHint: true,
                              ),
                              initialCountryCode: widget.countryCode,
                              onChanged: (phone) {
                                _phoneNumber = phone.completeNumber;
                              },
                              dropdownIconPosition: IconPosition.trailing,
                              flagsButtonPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14), // Match content padding
                              dropdownDecoration: const BoxDecoration(),
                              showDropdownIcon: true,
                              disableLengthCheck: true,
                              autovalidateMode: AutovalidateMode.disabled, // Disable validation
                            ),
                          ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Continue button
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6750A4),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Continue',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Divider
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[300])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or continue with',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[300])),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Google Sign In
              // Google Sign-In with improved error handling
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _handleGoogleSignIn,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.white,
                        elevation: 1,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/google_logo.svg',
                            width: 20,
                            height: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Continue with Google',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Footer
              FadeTransition(
                opacity: _fadeAnimation,
                child: Center(
                  child: Text(
                    'Powered by Alphabet (Pvt) Ltd',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
