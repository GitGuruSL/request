import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:request_marketplace/src/services/email_otp_service.dart';
import 'package:request_marketplace/src/auth/screens/profile_completion_screen.dart';

class EmailOtpVerificationScreen extends StatefulWidget {
  final String email;
  
  const EmailOtpVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<EmailOtpVerificationScreen> createState() => _EmailOtpVerificationScreenState();
}

class _EmailOtpVerificationScreenState extends State<EmailOtpVerificationScreen> {
  final EmailOtpService _emailOtpService = EmailOtpService();
  final TextEditingController _otpController = TextEditingController();
  final List<TextEditingController> _digitControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  
  bool _isLoading = false;
  bool _isResending = false;
  String _statusMessage = '';
  Timer? _timer;
  int _remainingSeconds = 600; // 10 minutes
  int _resendCooldown = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _statusMessage = 'OTP sent to ${widget.email}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    for (var controller in _digitControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          }
          if (_resendCooldown > 0) {
            _resendCooldown--;
          }
        });
      }
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    
    // Update the full OTP
    _otpController.text = _digitControllers.map((c) => c.text).join();
    
    // Auto-verify when all 6 digits are entered
    if (_otpController.text.length == 6) {
      _verifyOtp();
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 6) {
      _showError('Please enter the complete 6-digit OTP');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Verifying OTP...';
    });

    try {
      final isValid = await _emailOtpService.verifyEmailOtp(
        widget.email,
        _otpController.text,
      );

      if (isValid && mounted) {
        setState(() {
          _statusMessage = 'Email verified successfully!';
        });
        
        // Navigate to profile completion
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileCompletionScreen(
              emailOrPhone: widget.email,
              isEmail: true,
              isFromEmailVerification: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
        _clearOtp();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearOtp() {
    for (var controller in _digitControllers) {
      controller.clear();
    }
    _otpController.clear();
    _focusNodes[0].requestFocus();
  }

  Future<void> _resendOtp() async {
    if (_resendCooldown > 0) {
      _showError('Please wait $_resendCooldown seconds before requesting another OTP');
      return;
    }

    setState(() {
      _isResending = true;
      _statusMessage = 'Sending new OTP...';
    });

    try {
      await _emailOtpService.resendEmailOtp(widget.email);
      
      if (mounted) {
        setState(() {
          _statusMessage = 'New OTP sent to ${widget.email}';
          _remainingSeconds = 600; // Reset timer
          _resendCooldown = 60; // 1 minute cooldown
        });
        _clearOtp();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New OTP sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  void _showError(String message) {
    setState(() {
      _statusMessage = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true, // This ensures the screen resizes when keyboard appears
      body: SafeArea(
        child: SingleChildScrollView( // Wrap in SingleChildScrollView to prevent overflow
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 
                         MediaQuery.of(context).padding.top - 
                         AppBar().preferredSize.height - 48, // Account for appbar and padding
            ),
            child: IntrinsicHeight( // Use IntrinsicHeight instead of Column with Spacer
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
            
            // Email verification icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.email_outlined,
                size: 40,
                color: Colors.blue.shade600,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            const Text(
              'Verify Your Email',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Subtitle
            Text(
              'Enter the 6-digit code sent to',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 4),
            
            // Email address
            Text(
              widget.email,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // OTP Input Fields
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 50,
                  height: 60,
                  child: TextFormField(
                    controller: _digitControllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    decoration: InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.blue, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (value) => _onDigitChanged(index, value),
                  ),
                );
              }),
            ),
            
            const SizedBox(height: 24),
            
            // Status message
            Text(
              _statusMessage,
              style: TextStyle(
                color: _statusMessage.contains('Error') || _statusMessage.contains('Invalid') 
                    ? Colors.red 
                    : _statusMessage.contains('successfully')
                        ? Colors.green
                        : Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Timer
            if (_remainingSeconds > 0) ...[
              Text(
                'Code expires in ${_formatTime(_remainingSeconds)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
            ] else ...[
              const Text(
                'OTP has expired',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Verify Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading || _otpController.text.length != 6 
                    ? null 
                    : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Verify Email',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Resend OTP
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Didn't receive the code? "),
                TextButton(
                  onPressed: _isResending || _resendCooldown > 0 
                      ? null 
                      : _resendOtp,
                  child: Text(
                    _resendCooldown > 0 
                        ? 'Resend in ${_resendCooldown}s'
                        : 'Resend OTP',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _resendCooldown > 0 ? Colors.grey : Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24), // Reduced spacing
            
            // Help text
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Check your email inbox and spam folder',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'The verification code is valid for 10 minutes',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
