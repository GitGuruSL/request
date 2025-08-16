import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/country_service.dart';
import '../../services/sms_auth_service.dart';

class OTPScreen extends StatefulWidget {
  final String? verificationId;  // Legacy Firebase verification ID
  final String? sessionId;       // Legacy Custom OTP session ID
  final String? otpId;           // New SMS OTP ID
  final String? purpose;         // 'registration' or 'password_reset'
  final bool isNewUser;
  final String? emailOrPhone;
  final String? phoneNumber;
  final String? email;
  final bool isEmail;
  final bool isLogin;
  final bool isCustomOTP;
  final String? countryCode;
  final int? expiresIn;

  const OTPScreen({
    super.key,
    this.verificationId,
    this.sessionId,
    this.otpId,
    this.purpose,
    this.isNewUser = false,
    this.emailOrPhone,
    this.phoneNumber,
    this.email,
    this.isEmail = false,
    this.isLogin = false,
    this.isCustomOTP = false,
    this.countryCode,
    this.expiresIn,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> with TickerProviderStateMixin {
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
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
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  String get _otpCode => _controllers.map((controller) => controller.text).join();

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    
    // Auto-verify when all 6 digits are entered
    if (_otpCode.length == 6) {
      _handleVerify();
    }
  }

  void _handleVerify() async {
    if (_otpCode.length != 6) {
      _showErrorSnackBar('Please enter all 6 digits');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.otpId != null && widget.purpose != null) {
        // New SMS authentication system
        await _handleSMSAuthentication();
      } else if (widget.isCustomOTP) {
        // Legacy custom OTP verification
        await _handleCustomOTPVerification();
      } else {
        // Legacy Firebase OTP verification
        await _handleFirebaseOTPVerification();
      }
    } catch (e) {
      print("Error verifying OTP: $e");
      _showErrorSnackBar('Error verifying OTP. Please try again.');
      _clearOtp();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSMSAuthentication() async {
    final result = await SMSAuthService().verifyOTP(
      emailOrPhone: widget.emailOrPhone!,
      otp: _otpCode,
      otpId: widget.otpId!,
      purpose: widget.purpose!,
    );

    if (result['success']) {
      if (widget.purpose == 'registration') {
        // New user registration - go to profile completion
        Navigator.pushNamed(
          context,
          '/profile',
          arguments: {
            'emailOrPhone': widget.emailOrPhone,
            'isEmail': widget.isEmail,
            'countryCode': widget.countryCode,
            'otpId': widget.otpId,
          },
        );
      } else if (widget.purpose == 'password_reset') {
        // Password reset - go to new password screen
        Navigator.pushNamed(
          context,
          '/reset-password',
          arguments: {
            'emailOrPhone': widget.emailOrPhone,
            'isEmail': widget.isEmail,
            'otpId': widget.otpId,
          },
        );
      }
    } else {
      _showErrorSnackBar(result['message'] ?? 'Invalid OTP. Please try again.');
      _clearOtp();
    }
  }
  
  Future<void> _handleFirebaseOTPVerification() async {
    final authResult = await AuthService.instance.verifyLoginOTP(
      verificationId: widget.verificationId!,
      otp: _otpCode,
    );
    
    if (authResult.success) {
      if (widget.isNewUser) {
        // New user - go to profile completion
        Navigator.pushNamed(
          context,
          '/profile',
          arguments: {
            'emailOrPhone': widget.phoneNumber,
            'isEmail': false,
            'countryCode': widget.countryCode,
          },
        );
      } else {
        // Existing user - check if profile is complete before navigating
        final isProfileComplete = await AuthService.instance.isCurrentUserProfileComplete();
        
        if (isProfileComplete) {
          // Profile complete - go to home
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/home',
            (route) => false,
          );
        } else {
          // Profile incomplete - go to profile completion
          Navigator.pushNamed(
            context,
            '/profile',
            arguments: {
              'emailOrPhone': widget.phoneNumber ?? widget.email,
              'isEmail': widget.isEmail,
              'countryCode': widget.countryCode,
            },
          );
        }
      }
    } else {
      _showErrorSnackBar(authResult.error ?? 'Invalid OTP. Please try again.');
      _clearOtp();
    }
  }
  
  Future<void> _handleCustomOTPVerification() async {
    final isValid = await CustomOTPService.instance.verifyCustomOTP(
      sessionId: widget.sessionId!,
      otp: _otpCode,
    );
    
    if (isValid) {
      if (widget.isNewUser) {
        // New user registration - create temp account and go to profile
        await _createTempUserAccount();
      } else {
        // Handle other custom OTP purposes
        Navigator.pop(context, true);
      }
    } else {
      _showErrorSnackBar('Invalid OTP. Please try again.');
      _clearOtp();
    }
  }
  
  Future<void> _createTempUserAccount() async {
    try {
      final email = widget.email!;
      final tempPassword = _generateTempPassword();
      
      // Use the new registerWithEmail method that creates proper user document
      final authResult = await AuthService.instance.registerWithEmail(
        email: email,
        password: tempPassword,
      );
      
      if (authResult.success && authResult.user != null) {
        // Go to profile completion
        Navigator.pushNamed(
          context,
          '/profile',
          arguments: {
            'emailOrPhone': email,
            'isEmail': true,
            'tempPassword': tempPassword, // Pass temp password for user reference
          },
        );
      } else {
        throw Exception(authResult.error ?? 'Failed to create user account');
      }
    } catch (e) {
      print('Error creating temp user account: $e');
      _showErrorSnackBar('Failed to create account. Please try again.');
    }
  }
  
  String _generateTempPassword() {
    // Generate a temporary password for email users
    return 'temp_${DateTime.now().millisecondsSinceEpoch}_${_otpCode}';
  }

  void _clearOtp() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Uses theme background color (FAFAFAFF)
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      resizeToAvoidBottomInset: true, // This ensures the screen resizes when keyboard appears
      body: SafeArea(
        child: SingleChildScrollView( // Wrap in SingleChildScrollView to prevent overflow
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 
                             MediaQuery.of(context).padding.top - 
                             AppBar().preferredSize.height - 32, // Account for appbar and padding
                ),
                child: IntrinsicHeight( // Use IntrinsicHeight instead of Column with Spacer
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
              const SizedBox(height: 20),
              
              // Header
              Text(
                'Verify your ${widget.isEmail ? 'email' : 'phone'}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a 6-digit code to\n${widget.emailOrPhone}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              
              const SizedBox(height: 48),
              
              // OTP Input Boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 45,
                    height: 56,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                        color: Colors.grey.shade50,
                      ),
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) => _onOtpChanged(value, index),
                        onTap: () {
                          _controllers[index].selection = TextSelection.fromPosition(
                            TextPosition(offset: _controllers[index].text.length),
                          );
                        },
                      ),
                    ),
                  );
                }),
              ),
              
              const SizedBox(height: 32),
              
              // Resend Code Button
              Center(
                child: TextButton(
                  onPressed: () {
                    // TODO: Implement resend OTP functionality
                    _showErrorSnackBar('Resend feature coming soon');
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Didn\'t receive the code? Resend',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32), // Replaced Spacer with fixed spacing
              
              // Verify Button
              Container(
                width: double.infinity,
                height: 52,
                margin: const EdgeInsets.only(bottom: 32),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleVerify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.white,
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
                          'Verify',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
