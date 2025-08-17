import 'package:flutter/material.dart';

class OTPScreen extends StatefulWidget {
  final String? verificationId;
  final String? sessionId;
  final String? otpId;
  final String? purpose;
  final bool isNewUser;
  final String? emailOrPhone;
  final String? phoneNumber;

  const OTPScreen({
    super.key,
    this.verificationId,
    this.sessionId,
    this.otpId,
    this.purpose,
    this.isNewUser = false,
    this.emailOrPhone,
    this.phoneNumber,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OTP Verification'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.construction,
                size: 64,
                color: Colors.orange,
              ),
              SizedBox(height: 24),
              Text(
                'OTP Verification',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'This feature is being migrated to the new REST API.\nPlease use password-based login for now.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
