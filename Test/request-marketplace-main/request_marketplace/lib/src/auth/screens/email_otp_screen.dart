import 'package:flutter/material.dart';
import 'package:request_marketplace/src/auth/screens/profile_completion_screen.dart';
import 'package:request_marketplace/src/home/screens/home_screen.dart';
import 'package:request_marketplace/src/services/auth_service.dart';

class EmailOtpScreen extends StatefulWidget {
  final String email;
  final String countryCode;

  const EmailOtpScreen({
    super.key,
    required this.email,
    required this.countryCode,
  });

  @override
  State<EmailOtpScreen> createState() => _EmailOtpScreenState();
}

class _EmailOtpScreenState extends State<EmailOtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String _verificationId = '';

  @override
  void initState() {
    super.initState();
    _verificationId = "email_verification_${widget.email}";
  }

  void _handleVerify() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);

    try {
      // Verify the email OTP
      final result = await _authService.verifyOtp(_verificationId, _otpController.text);
      
      if (result != null && result.user != null) {
        // Check if this is an email OTP verified user (uid = 'email_otp_verified')
        if (result.user!.uid == 'email_otp_verified') {
          // This is a new user who just verified email OTP, take them to profile completion
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileCompletionScreen(
                  emailOrPhone: widget.email,
                  isEmail: true,
                  countryCode: widget.countryCode,
                  isFromEmailVerification: true,
                ),
              ),
              (route) => false,
            );
          }
        } else {
          // This is a real Firebase user, check if they have completed profile
          final hasProfile = await _authService.checkUserProfile(result.user!.uid);
          
          if (mounted) {
            if (hasProfile) {
              // User has profile, go to home
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            } else {
              // User needs to complete profile
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileCompletionScreen(
                    emailOrPhone: widget.email,
                    isEmail: true,
                    countryCode: widget.countryCode,
                    isFromEmailVerification: true,
                  ),
                ),
                (route) => false,
              );
            }
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid OTP. Please try again.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error verifying OTP: ${e.toString()}')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  void _handleResendOtp() async {
    setState(() => _isLoading = true);
    
    try {
      // Resend email OTP
      await _authService.sendOtp(
        value: widget.email,
        isEmail: true,
        codeSent: (verificationId, resendToken) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('OTP resent to your email')),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error resending OTP: ${e.toString()}')),
        );
      }
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 50),
            Text(
              'Enter Verification Code',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'We sent a verification code to ${widget.email}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              maxLength: 6,
              decoration: const InputDecoration(
                hintText: '000000',
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleVerify,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Verify'),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _isLoading ? null : _handleResendOtp,
              child: const Text('Resend Code'),
            ),
          ],
        ),
      ),
    );
  }
}
