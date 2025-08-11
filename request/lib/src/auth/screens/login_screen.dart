import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../services/auth_service.dart';
import '../../services/country_service.dart';
import '../../services/custom_otp_service.dart';

class LoginScreen extends StatefulWidget {
  final String countryCode;
  final String? phoneCode;

  const LoginScreen({
    super.key, 
    required this.countryCode,
    this.phoneCode,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  bool _isPhoneLogin = true;
  bool _isLoading = false;
  bool _showPasswordField = false;
  bool _obscurePassword = true;
  String? _currentEmail;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String phoneCode = '+1';
  String? completePhoneNumber; // Store the complete E.164 formatted number

  @override
  void initState() {
    super.initState();
    // Debug: Print received values
    print('🔍 LoginScreen received:');
    print('  - countryCode: ${widget.countryCode}');
    print('  - phoneCode: ${widget.phoneCode}');
    
    // Use the phone code passed from welcome screen (with + sign)
    if (widget.phoneCode != null) {
      phoneCode = widget.phoneCode!.startsWith('+') 
          ? widget.phoneCode! 
          : '+${widget.phoneCode!}';
      print('  - Set phoneCode to: $phoneCode');
    }
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;
    
    // Validate the form
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    try {
      if (_isPhoneLogin) {
        // Phone login flow
        final phoneNumber = completePhoneNumber ?? '${phoneCode}${_phoneController.text}';
        
        // Check if phone number is already registered
        final userCheck = await AuthService.instance.checkUserExists(phoneNumber: phoneNumber);
        
        if (userCheck.exists) {
          // Existing user - send Firebase OTP for login
          await _sendLoginOTP(phoneNumber);
        } else {
          // New user - send Firebase OTP for registration
          await _sendRegistrationOTP(phoneNumber);
        }
        
      } else {
        // Email login flow
        final email = _emailController.text.trim();
        
        if (_showPasswordField) {
          // User has entered password, attempt login
          await _loginWithPassword(email, _passwordController.text);
        } else {
          // Check if email is already registered
          final userCheck = await AuthService.instance.checkUserExists(email: email);
          
          if (userCheck.exists) {
            // Existing user - show password field
            setState(() {
              _showPasswordField = true;
              _currentEmail = email;
              _isLoading = false;
            });
          } else {
            // New user - send OTP for registration
            await _sendEmailRegistrationOTP(email);
          }
        }
      }
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _loginWithPassword(String email, String password) async {
    try {
      final authResult = await AuthService.instance.signInWithEmailPassword(
        email: email,
        password: password,
      );
      
      setState(() {
        _isLoading = false;
      });
      
      if (authResult.success) {
        // Check if profile is complete before navigating to home
        final isProfileComplete = await AuthService.instance.isCurrentUserProfileComplete();
        
        if (isProfileComplete) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          Navigator.pushReplacementNamed(context, '/role-selection');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authResult.error ?? 'Login failed')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    }
  }
  
  Future<void> _sendLoginOTP(String phoneNumber) async {
    await AuthService.instance.sendLoginOTP(
      phoneNumber: phoneNumber,
      onCodeSent: (verificationId) {
        setState(() {
          _isLoading = false;
        });
        Navigator.pushNamed(
          context,
          '/otp',
          arguments: {
            'verificationId': verificationId,
            'phoneNumber': phoneNumber,
            'isNewUser': false,
            'isLogin': true,
          },
        );
      },
      onError: (error) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      },
      onAutoVerified: (user) async {
        setState(() {
          _isLoading = false;
        });
        
        // Check if user profile is complete before navigating to home
        final isProfileComplete = await AuthService.instance.isCurrentUserProfileComplete();
        
        if (isProfileComplete) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        } else {
          // Profile not complete, redirect to registration flow
          Navigator.pushNamedAndRemoveUntil(context, '/register', (route) => false);
        }
      },
    );
  }
  
  Future<void> _sendRegistrationOTP(String phoneNumber) async {
    await AuthService.instance.sendRegistrationOTP(
      phoneNumber: phoneNumber,
      onCodeSent: (verificationId) {
        setState(() {
          _isLoading = false;
        });
        Navigator.pushNamed(
          context,
          '/otp',
          arguments: {
            'verificationId': verificationId,
            'phoneNumber': phoneNumber,
            'isNewUser': true,
            'isLogin': false,
          },
        );
      },
      onError: (error) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      },
      onAutoVerified: (user) {
        setState(() {
          _isLoading = false;
        });
        // New user - go to profile completion
        Navigator.pushNamed(context, '/profile');
      },
    );
  }
  
  Future<void> _sendEmailRegistrationOTP(String email) async {
    try {
      // For email registration, we'll use a custom OTP system
      final sessionId = await CustomOTPService.instance.sendCustomOTP(
        identifier: email,
        purpose: 'email_registration',
      );
      
      setState(() {
        _isLoading = false;
      });
      
      Navigator.pushNamed(
        context,
        '/otp',
        arguments: {
          'sessionId': sessionId,
          'email': email,
          'isNewUser': true,
          'isLogin': false,
          'isCustomOTP': true,
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send OTP: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Uses theme background color (FAFAFAFF)
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 
                           MediaQuery.of(context).padding.top - 
                           MediaQuery.of(context).padding.bottom - 48,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      
                      // Back button
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Title
                      const Text(
                        'Welcome Back!',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      const Text(
                        'Sign in to continue',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Phone/Email toggle
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isPhoneLogin = true;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: _isPhoneLogin ? Theme.of(context).colorScheme.primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Phone',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _isPhoneLogin ? Colors.white : Colors.grey[600],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isPhoneLogin = false;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: !_isPhoneLogin ? Theme.of(context).colorScheme.primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Email',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: !_isPhoneLogin ? Colors.white : Colors.grey[600],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Input field form
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: _isPhoneLogin
                                ? IntlPhoneField(
                                    key: const ValueKey('phone'),
                                    controller: _phoneController,
                                    decoration: const InputDecoration(
                                      labelText: 'Phone Number',
                                      prefixIcon: Icon(Icons.phone),
                                    ),
                                    initialCountryCode: widget.countryCode.isNotEmpty 
                                        ? widget.countryCode 
                                        : 'US',
                                    onCountryChanged: (country) {
                                      phoneCode = '+${country.dialCode}';
                                    },
                                    onChanged: (phone) {
                                      completePhoneNumber = phone.completeNumber;
                                    },
                                    validator: (phone) {
                                      if (phone == null || phone.number.isEmpty) {
                                        return 'Please enter a valid phone number';
                                      }
                                      return null;
                                    },
                                  )
                                : TextFormField(
                                    key: const ValueKey('email'),
                                    controller: _emailController,
                                    decoration: const InputDecoration(
                                      labelText: 'Email Address',
                                      prefixIcon: Icon(Icons.email),
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    enabled: !_showPasswordField,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your email address';
                                      }
                                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                        return 'Please enter a valid email address';
                                      }
                                      return null;
                                    },
                                  ),
                            ),
                            
                            // Password field (shown only when email user exists)
                            if (!_isPhoneLogin && _showPasswordField) ...[
                              const SizedBox(height: 16),
                              Text(
                                'Welcome back! Please enter your password for:',
                                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _currentEmail ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                key: const ValueKey('password'),
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock),
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _showPasswordField = false;
                                      _emailController.clear();
                                      _passwordController.clear();
                                    });
                                  },
                                  child: const Text('Use different email'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Login button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  _isPhoneLogin 
                                    ? 'Send OTP' 
                                    : (_showPasswordField ? 'Login' : 'Continue'),
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Terms text
                      Text.rich(
                        TextSpan(
                          text: 'By continuing, you agree to our ',
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                          children: [
                            TextSpan(
                              text: 'Terms of Service',
                              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Bottom text
                      Center(
                        child: Text.rich(
                          TextSpan(
                            text: "Don't have an account? ",
                            style: const TextStyle(color: Colors.grey),
                            children: [
                              TextSpan(
                                text: 'Sign up',
                                style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
                              ),
                            ],
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
