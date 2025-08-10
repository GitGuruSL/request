// Phone Number Verification Widget
// Handles the new phone verification logic with override capabilities

import 'package:flutter/material.dart';
import '../services/phone_verification_service.dart';

class PhoneVerificationWidget extends StatefulWidget {
  final String userId;
  final String userType; // 'business', 'driver'
  final String collection;
  final Function(bool verified, String? message) onVerificationComplete;
  final String? initialPhoneNumber;

  const PhoneVerificationWidget({
    super.key,
    required this.userId,
    required this.userType,
    required this.collection,
    required this.onVerificationComplete,
    this.initialPhoneNumber,
  });

  @override
  State<PhoneVerificationWidget> createState() => _PhoneVerificationWidgetState();
}

class _PhoneVerificationWidgetState extends State<PhoneVerificationWidget> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _phoneService = PhoneVerificationService();
  
  bool _isCheckingPhone = false;
  bool _isSendingOTP = false;
  bool _isVerifyingOTP = false;
  bool _otpSent = false;
  bool _canRegister = false;
  String? _phoneMessage;
  String? _otpMessage;
  Map<String, dynamic>? _phoneCheckResult;

  @override
  void initState() {
    super.initState();
    if (widget.initialPhoneNumber != null) {
      _phoneController.text = widget.initialPhoneNumber!;
      _checkPhoneAvailability();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Phone Number Verification',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Verify your phone number to complete ${widget.userType} registration',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            
            // Phone Number Input
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                hintText: '+94771234567',
                prefixIcon: const Icon(Icons.phone),
                border: const OutlineInputBorder(),
                suffixIcon: _isCheckingPhone
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        onPressed: _checkPhoneAvailability,
                        icon: const Icon(Icons.search),
                      ),
              ),
              keyboardType: TextInputType.phone,
              onChanged: (value) {
                setState(() {
                  _otpSent = false;
                  _canRegister = false;
                  _phoneMessage = null;
                  _otpMessage = null;
                });
              },
            ),
            
            // Phone Check Result
            if (_phoneMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _canRegister ? Colors.green[50] : Colors.orange[50],
                  border: Border.all(
                    color: _canRegister ? Colors.green : Colors.orange,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _canRegister ? Icons.check_circle : Icons.info,
                      color: _canRegister ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _phoneMessage!,
                        style: TextStyle(
                          color: _canRegister ? Colors.green[800] : Colors.orange[800],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Show replacement details if applicable
            if (_phoneCheckResult?['willReplace'] == true) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  border: Border.all(color: Colors.blue),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This will replace unverified registrations:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...(_phoneCheckResult!['replaceData'] as List).map((entry) => 
                      Text(
                        '• ${entry['userType']} registration (${entry['collection']})',
                        style: TextStyle(color: Colors.blue[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Send OTP Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canRegister && !_otpSent ? _sendOTP : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isSendingOTP
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _otpSent ? 'OTP Sent' : 'Send Verification Code',
                        style: const TextStyle(color: Colors.white),
                      ),
              ),
            ),

            // OTP Input (shown after OTP is sent)
            if (_otpSent) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _otpController,
                decoration: const InputDecoration(
                  labelText: 'Verification Code',
                  hintText: 'Enter 6-digit code',
                  prefixIcon: Icon(Icons.sms),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),

              // OTP Message
              if (_otpMessage != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _otpMessage!.contains('successfully') 
                        ? Colors.green[50] 
                        : Colors.red[50],
                    border: Border.all(
                      color: _otpMessage!.contains('successfully') 
                          ? Colors.green 
                          : Colors.red,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _otpMessage!.contains('successfully') 
                            ? Icons.check_circle 
                            : Icons.error,
                        color: _otpMessage!.contains('successfully') 
                            ? Colors.green 
                            : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _otpMessage!,
                          style: TextStyle(
                            color: _otpMessage!.contains('successfully') 
                                ? Colors.green[800] 
                                : Colors.red[800],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Verify OTP Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _otpController.text.length == 6 ? _verifyOTP : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isVerifyingOTP
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Verify Phone Number',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),

              const SizedBox(height: 8),

              // Resend OTP
              TextButton(
                onPressed: _sendOTP,
                child: const Text('Resend Verification Code'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _checkPhoneAvailability() async {
    if (_phoneController.text.trim().isEmpty) return;

    setState(() {
      _isCheckingPhone = true;
      _phoneMessage = null;
      _canRegister = false;
    });

    try {
      final result = await _phoneService.checkPhoneNumberAvailability(
        phoneNumber: _phoneController.text.trim(),
        userId: widget.userId,
        userType: widget.userType,
        collection: widget.collection,
      );

      setState(() {
        _phoneCheckResult = result;
        _canRegister = result['canRegister'] ?? false;
        _phoneMessage = result['message'];
      });
    } catch (e) {
      setState(() {
        _phoneMessage = 'Error checking phone number: $e';
        _canRegister = false;
      });
    } finally {
      setState(() {
        _isCheckingPhone = false;
      });
    }
  }

  Future<void> _sendOTP() async {
    if (!_canRegister) return;

    setState(() {
      _isSendingOTP = true;
      _otpMessage = null;
    });

    try {
      await _phoneService.storeOTP(
        phoneNumber: _phoneController.text.trim(),
        otp: _phoneService.generateOTP(),
        userType: widget.userType,
        context: {
          'userId': widget.userId,
          'action': '${widget.userType}_phone_verification',
        },
      );

      setState(() {
        _otpSent = true;
        _otpMessage = 'Verification code sent to ${_phoneController.text.trim()}';
      });
    } catch (e) {
      setState(() {
        _otpMessage = 'Error sending verification code: $e';
      });
    } finally {
      setState(() {
        _isSendingOTP = false;
      });
    }
  }

  Future<void> _verifyOTP() async {
    setState(() {
      _isVerifyingOTP = true;
      _otpMessage = null;
    });

    try {
      final result = await _phoneService.verifyOTP(
        phoneNumber: _phoneController.text.trim(),
        otp: _otpController.text.trim(),
      );

      setState(() {
        _otpMessage = result['message'];
      });

      if (result['success']) {
        widget.onVerificationComplete(true, 'Phone number verified successfully');
      } else {
        widget.onVerificationComplete(false, result['message']);
      }
    } catch (e) {
      final errorMessage = 'Error verifying code: $e';
      setState(() {
        _otpMessage = errorMessage;
      });
      widget.onVerificationComplete(false, errorMessage);
    } finally {
      setState(() {
        _isVerifyingOTP = false;
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }
}
