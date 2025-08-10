import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../services/phone_number_service.dart';

class PhoneVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final VoidCallback? onVerificationSuccess;

  const PhoneVerificationScreen({
    super.key,
    required this.phoneNumber,
    this.onVerificationSuccess,
  });

  @override
  State<PhoneVerificationScreen> createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _phoneService = PhoneNumberService();
  
  bool _isVerifying = false;
  bool _isResending = false;
  int _resendCountdown = 0;
  Timer? _countdownTimer;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startResendCountdown() {
    setState(() {
      _resendCountdown = 120; // 2 minutes
    });
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  String _formatCountdown(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      await _phoneService.verifyPhoneNumberWithCode(
        widget.phoneNumber,
        _otpController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Phone number verified successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Call success callback if provided
        widget.onVerificationSuccess?.call();

        // Navigate back with success result
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      final result = await _phoneService.resendOtp(widget.phoneNumber);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result),
            backgroundColor: Colors.blue,
          ),
        );
        
        // Clear current OTP input
        _otpController.clear();
        
        // Restart countdown
        _startResendCountdown();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Verify Phone Number',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1D1B20),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1D1B20),
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              
              // Phone verification icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF1976D2),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.smartphone,
                  size: 40,
                  color: Color(0xFF1976D2),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Title
              const Text(
                'Verify Your Phone Number',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1D1B20),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              // Subtitle with phone number
              Text(
                'We sent a verification code to',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 6),
              
              Text(
                widget.phoneNumber,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1976D2),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // OTP Input Container
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter Verification Code',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1D1B20),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // OTP Input Field
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 4,
                        color: Color(0xFF1D1B20),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: InputDecoration(
                        hintText: '123456',
                        hintStyle: const TextStyle(
                          color: Color(0xFF999999),
                          letterSpacing: 4,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        counterText: '',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter the verification code';
                        }
                        if (value.trim().length != 6) {
                          return 'Please enter a valid 6-digit code';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          _errorMessage = null;
                        });
                        // Auto-verify when 6 digits entered
                        if (value.length == 6) {
                          _verifyOtp();
                        }
                      },
                    ),
                    
                    // Error message
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade600,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Verify Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Verify Phone Number',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Resend OTP section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Didn't receive the code?",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    if (_resendCountdown > 0) ...[
                      Text(
                        'Resend available in ${_formatCountdown(_resendCountdown)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF999999),
                        ),
                      ),
                    ] else ...[
                      TextButton(
                        onPressed: _isResending ? null : _resendOtp,
                        child: _isResending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
                                ),
                              )
                            : const Text(
                                'Resend Code',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1976D2),
                                ),
                              ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Development mode indicator
              if (kDebugMode)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.developer_mode,
                        color: Colors.orange.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Development Mode: Check console for OTP code',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
