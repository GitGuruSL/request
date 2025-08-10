import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:request_marketplace/src/navigation/main_navigation_screen.dart';
import 'package:request_marketplace/src/services/auth_service.dart';

class ProfileCompletionScreen extends StatefulWidget {
  final String emailOrPhone;
  final bool isEmail;
  final String? countryCode;
  final bool isFromEmailVerification; // New parameter to track if user came from email OTP verification

  const ProfileCompletionScreen({
    super.key,
    required this.emailOrPhone,
    required this.isEmail,
    this.countryCode,
    this.isFromEmailVerification = false, // Default to false for backward compatibility
  });

  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String _phoneNumber = '';
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.isEmail) {
      _emailController.text = widget.emailOrPhone;
    } else {
      _phoneController.text = widget.emailOrPhone;
      _phoneNumber = widget.emailOrPhone;
    }
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.isEmail) {
        // For email users, always create Firebase Auth user first, then save profile data
        print("Creating Firebase Auth user for email: ${_emailController.text.trim()}"); // Debug log
        
        final userCredential = await _authService.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Check if user creation was successful
        final user = userCredential?.user ?? FirebaseAuth.instance.currentUser;
        if (user != null) {
          print("Firebase Auth user created successfully: ${user.uid}"); // Debug log
          
          // Save user profile data to Firestore
          await _authService.saveUserData(
            uid: user.uid,
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phoneNumber: _phoneNumber,
          );

          print("Profile data saved, navigating to home screen..."); // Debug log
          
          if (mounted) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Registration completed! Welcome to Request!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            
            // Small delay to show the success message
            await Future.delayed(const Duration(milliseconds: 500));
            
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const MainNavigationScreen(),
              ),
              (route) => false,
            );
          }
        } else {
          // This should not happen, but handle the case anyway
          print("User creation failed - no user credential and no current user"); // Debug log
          throw Exception("User creation failed");
        }
      } else {
        // New user via Phone
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await _authService.saveUserData(
            uid: user.uid,
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phoneNumber: _phoneNumber,
          );
          if (mounted) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Registration completed! Welcome to Request!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            
            // Small delay to show the success message
            await Future.delayed(const Duration(milliseconds: 500));
            
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const MainNavigationScreen(),
              ),
              (route) => false,
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'No authenticated user found. Please try logging in again.')),
            );
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException: ${e.code} - ${e.message}"); // Debug log
      if (mounted) {
        String errorMessage = 'An error occurred during registration.';
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = 'This email address is already registered.';
            break;
          case 'weak-password':
            errorMessage = 'The password provided is too weak.';
            break;
          case 'invalid-email':
            errorMessage = 'The email address is not valid.';
            break;
          default:
            errorMessage = e.message ?? 'An unknown error occurred.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      print("General exception: $e"); // Debug log
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Profile'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                if (widget.isEmail)
                  IntlPhoneField(
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                    ),
                    initialCountryCode: widget.countryCode ?? 'US',
                    onChanged: (phone) {
                      _phoneNumber = phone.completeNumber;
                    },
                    validator: (phone) {
                      if (phone == null || phone.number.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      return null;
                    },
                  )
                else
                  TextFormField(
                    controller: _emailController,
                    decoration:
                        const InputDecoration(labelText: 'Email (optional)'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value != null &&
                          value.isNotEmpty &&
                          !value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 10),
                if (widget.isEmail) ...[
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration:
                        const InputDecoration(labelText: 'Confirm Password'),
                    obscureText: true,
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Register'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
