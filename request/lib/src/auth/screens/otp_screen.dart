import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/rest_auth_service.dart';

class OTPScreen extends StatefulWidget {
  final String emailOrPhone;
  final bool isEmail;
  final bool isNewUser;
  final String countryCode;

  const OTPScreen({
    super.key,
    required this.emailOrPhone,
    required this.isEmail,
    required this.isNewUser,
    required this.countryCode,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  String _otpToken = '';

  @override
  void initState() {
    super.initState();
    _sendOTP();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _sendOTP() async {
    setState(() => _isResending = true);

    try {
      final authService = RestAuthService.instance;
      final result = await authService.sendOTP(
        emailOrPhone: widget.emailOrPhone,
        isEmail: widget.isEmail,
        countryCode: widget.countryCode,
      );

      if (result.success) {
        _otpToken = result.otpToken ?? '';
        _showMessage('OTP sent successfully', isError: false);
      } else {
        _showMessage(result.error ?? 'Failed to send OTP');
      }
    } catch (e) {
      _showMessage('Error sending OTP: $e');
    } finally {
      setState(() => _isResending = false);
    }
  }

  Future<void> _verifyOTP() async {
    final otp = _controllers.map((c) => c.text).join();

    if (otp.length != 6) {
      _showMessage('Please enter complete 6-digit OTP');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = RestAuthService.instance;
      final result = await authService.verifyOTP(
        emailOrPhone: widget.emailOrPhone,
        otp: otp,
        otpToken: _otpToken,
      );

      if (result.success) {
        // For brand new users we should collect a password next (registration not complete yet)
        if (widget.isNewUser) {
          // New user: proceed to profile completion flow after verification
          Navigator.pushReplacementNamed(
            context,
            '/profile',
            arguments: {
              'isNewUser': true,
              'emailOrPhone': widget.emailOrPhone,
              'isEmail': widget.isEmail,
              'countryCode': widget.countryCode,
              'otpToken': _otpToken,
            },
          );
        } else {
          // Existing user verifying contact -> go to profile/dashboard
          Navigator.pushReplacementNamed(
            context,
            '/profile',
            arguments: {
              'emailOrPhone': widget.emailOrPhone,
              'isEmail': widget.isEmail,
              'countryCode': widget.countryCode,
              'otpToken': _otpToken,
            },
          );
        }
      } else {
        _showMessage(result.error ?? 'Invalid OTP');
      }
    } catch (e) {
      _showMessage('Error verifying OTP: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void _onOTPChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Auto-verify when all fields are filled
    if (index == 5 && value.isNotEmpty) {
      final otp = _controllers.map((c) => c.text).join();
      if (otp.length == 6) {
        _verifyOTP();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verify ${widget.isEmail ? 'Email' : 'Phone'}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Title
            Text(
              'Enter Verification Code',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
            ),

            const SizedBox(height: 12),

            // Subtitle
            Text(
              'We sent a 6-digit code to ${widget.emailOrPhone}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),

            const SizedBox(height: 40),

            // OTP Input Fields
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 50,
                  child: TextFormField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    decoration: InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Colors.blue, width: 2),
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (value) => _onOTPChanged(index, value),
                  ),
                );
              }),
            ),

            const SizedBox(height: 40),

            // Verify Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOTP,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Verify',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // Resend Button
            Center(
              child: TextButton(
                onPressed: _isResending ? null : _sendOTP,
                child: _isResending
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Resending...'),
                        ],
                      )
                    : const Text(
                        'Resend Code',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
