import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'dart:async';

import '../services/unified_otp_service.dart';

/// Unified OTP Verification Widget
/// 
/// A comprehensive widget that handles phone verification with OTP
/// across all app modules with automatic verification detection
/// 
/// Features:
/// - Auto-detects if phone is already verified
/// - Consistent 6-digit OTP input
/// - Context-aware verification
/// - Automatic verification when same phone is reused
/// - Countdown timer for resend
/// - Loading states and error handling
class UnifiedOtpWidget extends StatefulWidget {
  final String? initialPhoneNumber;
  final VerificationContext context;
  final String? userType;
  final Function(String phoneNumber, bool isVerified) onVerificationComplete;
  final Function(String error)? onError;
  final Map<String, dynamic>? additionalData;
  final bool showPhoneInput;
  final String? title;
  final String? subtitle;

  const UnifiedOtpWidget({
    Key? key,
    this.initialPhoneNumber,
    required this.context,
    this.userType,
    required this.onVerificationComplete,
    this.onError,
    this.additionalData,
    this.showPhoneInput = true,
    this.title,
    this.subtitle,
  }) : super(key: key);

  @override
  State<UnifiedOtpWidget> createState() => _UnifiedOtpWidgetState();
}

class _UnifiedOtpWidgetState extends State<UnifiedOtpWidget> {
  final UnifiedOtpService _otpService = UnifiedOtpService();
  
  // Controllers
  final TextEditingController _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (index) => FocusNode());

  // State variables
  bool _isLoading = false;
  bool _isOtpSent = false;
  bool _isAutoVerified = false;
  String? _errorMessage;
  String? _successMessage;
  String _phoneNumber = '';
  int _resendCountdown = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialPhoneNumber != null) {
      _phoneController.text = widget.initialPhoneNumber!;
      _phoneNumber = widget.initialPhoneNumber!;
      // Auto-check verification status if phone is pre-filled
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkInitialVerificationStatus());
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkInitialVerificationStatus() async {
    if (_phoneNumber.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final result = await _otpService.checkPhoneVerificationStatus(
        phoneNumber: _phoneNumber,
        context: widget.context,
        userType: widget.userType,
      );

      if (result['canAutoVerify'] == true) {
        setState(() {
          _isAutoVerified = true;
          _successMessage = result['autoVerifyReason'];
          _errorMessage = null;
        });
        
        // Notify parent that verification is complete
        widget.onVerificationComplete(_phoneNumber, true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error checking verification status: $e';
      });
      widget.onError?.call(_errorMessage!);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendOtp() async {
    if (_phoneNumber.isEmpty) {
      setState(() => _errorMessage = 'Please enter a valid phone number');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final result = await _otpService.sendVerificationOtp(
        phoneNumber: _phoneNumber,
        context: widget.context,
        userType: widget.userType,
        additionalData: widget.additionalData,
      );

      if (result['success'] == true) {
        if (result['autoVerified'] == true) {
          // Phone was auto-verified
          setState(() {
            _isAutoVerified = true;
            _successMessage = result['message'];
          });
          widget.onVerificationComplete(_phoneNumber, true);
        } else {
          // OTP was sent
          setState(() {
            _isOtpSent = true;
            _successMessage = result['message'];
          });
          _startResendCountdown();
        }
      } else {
        setState(() => _errorMessage = result['error'] ?? 'Failed to send OTP');
        widget.onError?.call(_errorMessage!);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error: $e');
      widget.onError?.call(_errorMessage!);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final otpCode = _otpControllers.map((controller) => controller.text).join();
    
    if (otpCode.length != 6) {
      setState(() => _errorMessage = 'Please enter the complete 6-digit OTP');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _otpService.verifyOtp(
        phoneNumber: _phoneNumber,
        otpCode: otpCode,
        context: widget.context,
        userType: widget.userType,
      );

      if (result['success'] == true) {
        setState(() {
          _successMessage = result['message'];
          _errorMessage = null;
        });
        widget.onVerificationComplete(_phoneNumber, true);
      } else {
        setState(() => _errorMessage = result['error'] ?? 'Verification failed');
        widget.onError?.call(_errorMessage!);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error: $e');
      widget.onError?.call(_errorMessage!);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _otpService.resendOtp(
        phoneNumber: _phoneNumber,
        context: widget.context,
      );

      if (result['success'] == true) {
        setState(() => _successMessage = result['message']);
        _startResendCountdown();
        _clearOtpFields();
      } else {
        setState(() => _errorMessage = result['error'] ?? 'Failed to resend OTP');
        widget.onError?.call(_errorMessage!);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error: $e');
      widget.onError?.call(_errorMessage!);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _startResendCountdown() {
    setState(() => _resendCountdown = 60);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _resendCountdown--);
      if (_resendCountdown <= 0) {
        timer.cancel();
      }
    });
  }

  void _clearOtpFields() {
    for (final controller in _otpControllers) {
      controller.clear();
    }
    _otpFocusNodes[0].requestFocus();
  }

  void _onPhoneChanged(String phoneNumber) {
    setState(() {
      _phoneNumber = phoneNumber;
      _isOtpSent = false;
      _isAutoVerified = false;
      _errorMessage = null;
      _successMessage = null;
    });
    
    // Auto-check verification status when phone changes
    if (phoneNumber.length > 10) {
      _checkInitialVerificationStatus();
    }
  }

  void _onOtpChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }

    // Auto-verify when all 6 digits are entered
    final otpCode = _otpControllers.map((controller) => controller.text).join();
    if (otpCode.length == 6) {
      _verifyOtp();
    }
  }

  String _getContextTitle() {
    if (widget.title != null) return widget.title!;
    
    switch (widget.context) {
      case VerificationContext.login:
        return 'Phone Verification';
      case VerificationContext.profileCompletion:
        return 'Complete Your Profile';
      case VerificationContext.businessRegistration:
        return 'Verify Business Phone';
      case VerificationContext.driverRegistration:
        return 'Verify Driver Phone';
      case VerificationContext.requestForm:
        return 'Add Contact Phone';
      case VerificationContext.responseForm:
        return 'Share Contact Phone';
      case VerificationContext.accountManagement:
        return 'Manage Phone Numbers';
      case VerificationContext.additionalPhone:
        return 'Add Phone Number';
    }
  }

  String _getContextSubtitle() {
    if (widget.subtitle != null) return widget.subtitle!;
    
    if (_isAutoVerified) {
      return 'Phone number verified automatically';
    }
    
    switch (widget.context) {
      case VerificationContext.login:
        return 'We\'ll send a 6-digit code to verify your number';
      case VerificationContext.profileCompletion:
        return 'Verify your phone number to complete registration';
      case VerificationContext.businessRegistration:
        return 'Verify your business contact number';
      case VerificationContext.driverRegistration:
        return 'Verify your driver contact number';
      case VerificationContext.requestForm:
        return 'Add additional contact number for this request';
      case VerificationContext.responseForm:
        return 'Share your contact number with the requester';
      case VerificationContext.accountManagement:
        return 'Add and manage your phone numbers';
      case VerificationContext.additionalPhone:
        return 'Add another verified phone number to your account';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16), // Reduced from 20
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Add this to minimize height
          children: [
            // Title and subtitle
            Text(
              _getContextTitle(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6), // Reduced from 8
            Text(
              _getContextSubtitle(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16), // Reduced from 20

            // Auto-verified success state
            if (_isAutoVerified) ...[
              Container(
                padding: const EdgeInsets.all(12), // Reduced from 16
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  border: Border.all(color: Colors.green[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Phone Verified',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                          if (_successMessage != null)
                            Text(
                              _successMessage!,
                              style: TextStyle(color: Colors.green[700]),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Phone input section
              if (widget.showPhoneInput) ...[
                IntlPhoneField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  initialCountryCode: 'LK',
                  onChanged: (phone) => _onPhoneChanged(phone.completeNumber),
                ),
                const SizedBox(height: 12), // Reduced from 16
              ],

              // Send OTP button
              if (!_isOtpSent) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendOtp,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Send Verification Code'),
                  ),
                ),
              ],

              // OTP input section
              if (_isOtpSent) ...[
                const Text(
                  'Enter Verification Code',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10), // Reduced from 12
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 45, // Reduced from 50
                      height: 45, // Reduced from 50
                      child: TextField(
                        controller: _otpControllers[index],
                        focusNode: _otpFocusNodes[index],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16, // Reduced from 18
                          fontWeight: FontWeight.bold,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(1),
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          counterText: '',
                          contentPadding: EdgeInsets.all(8), // Add this for better spacing
                        ),
                        onChanged: (value) => _onOtpChanged(index, value),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12), // Reduced from 16

                // Resend button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _resendCountdown > 0
                          ? 'Resend in ${_resendCountdown}s'
                          : 'Didn\'t receive the code?',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12), // Reduced font size
                    ),
                    TextButton(
                      onPressed: _resendCountdown <= 0 && !_isLoading
                          ? _resendOtp
                          : null,
                      child: const Text('Resend'),
                    ),
                  ],
                ),

                // Verify button
                const SizedBox(height: 12), // Reduced from 16
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOtp,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Verify Code'),
                  ),
                ),
              ],
            ],

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 12), // Reduced from 16
              Container(
                padding: const EdgeInsets.all(10), // Reduced from 12
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[600], size: 20), // Reduced size
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[800], fontSize: 13), // Reduced font size
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Success message (for OTP sent)
            if (_successMessage != null && !_isAutoVerified) ...[
              const SizedBox(height: 12), // Reduced from 16
              Container(
                padding: const EdgeInsets.all(10), // Reduced from 12
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  border: Border.all(color: Colors.green[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green[600], size: 20), // Reduced size
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: TextStyle(color: Colors.green[800], fontSize: 13), // Reduced font size
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
