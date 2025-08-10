import 'dart:async';

import 'package:flutter/material.dart';
import 'package:request_marketplace/src/auth/screens/login_screen.dart';
import 'package:request_marketplace/src/navigation/main_navigation_screen.dart';
import 'package:request_marketplace/src/services/auth_service.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final AuthService _authService = AuthService();
  Timer? _timer;
  bool _isVerified = false;
  bool _isLoadingResend = false;
  String _statusMessage = 'Sending verification email...';

  @override
  void initState() {
    super.initState();
    _sendInitialVerificationEmail();
    _startVerificationCheck();
  }

  Future<void> _sendInitialVerificationEmail() async {
    try {
      await _authService.sendEmailVerification();
      if (mounted) {
        setState(() {
          _statusMessage = 'Verification email sent! Please check your inbox.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Failed to send verification email: ${e.toString()}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _startVerificationCheck() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        await _authService.currentUser?.reload();
        final user = _authService.currentUser;
        if (user?.emailVerified ?? false) {
          timer.cancel();
          setState(() {
            _isVerified = true;
            _statusMessage = 'Email verified successfully!';
          });
          // Navigate to home after a short delay to show the success message
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
                (route) => false,
              );
            }
          });
        }
      } catch (e) {
        print('Error checking verification status: $e');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isLoadingResend = true;
    });
    try {
      await _authService.resendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('A new verification email has been sent.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingResend = false;
        });
      }
    }
  }

  Widget _buildTroubleshootingItem(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = _authService.currentUser?.email ?? 'your email';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isVerified)
                const Column(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 80),
                    SizedBox(height: 20),
                    Text(
                      'Email Verified!',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'You will be redirected shortly.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    Text(
                      'A verification email has been sent to $userEmail',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Text(
                        _statusMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 24),
                    const Text(
                      'Waiting for verification...',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed:
                          _isLoadingResend ? null : _resendVerificationEmail,
                      child: _isLoadingResend
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Resend Email'),
                    ),
                    const SizedBox(height: 12),
                    
                    // Troubleshooting section
                    ExpansionTile(
                      title: const Text('Not receiving emails? 📧'),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.orange, size: 16),
                                  SizedBox(width: 8),
                                  Text('Troubleshooting Steps:', style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildTroubleshootingItem('📥', 'Check your spam/junk folder'),
                              _buildTroubleshootingItem('✉️', 'Make sure the email address is correct'),
                              _buildTroubleshootingItem('⏰', 'Wait 2-5 minutes for email delivery'),
                              _buildTroubleshootingItem('🌐', 'Check your internet connection'),
                              _buildTroubleshootingItem('🔄', 'Try the "Resend Email" button'),
                              _buildTroubleshootingItem('📧', 'Try a different email provider (Gmail, Outlook)'),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                                ),
                                child: const Text(
                                  '🔧 Development Note: Email delivery can be delayed in development mode. In production, emails are delivered faster.',
                                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        _timer?.cancel();
                        _authService.signOut();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen(
                                    countryCode:
                                        'US', // Or find a way to persist this
                                  )),
                          (route) => false,
                        );
                      },
                      child: const Text('Cancel'),
                    ),
                    
                    // Development bypass (remove in production)
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.code, color: Colors.orange, size: 16),
                              SizedBox(width: 8),
                              Text('Development Mode', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Email not working? This is common in development. You can continue testing the app:',
                            style: TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              _timer?.cancel();
                              // Skip email verification for development
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
                                (route) => false,
                              );
                            },
                            child: const Text('Continue Without Verification (Dev Only)'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
