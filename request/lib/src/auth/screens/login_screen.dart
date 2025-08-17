import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../services/rest_auth_service.dart';

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

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isPhoneLogin = true;
  bool _isLoading = false;

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
      String emailOrPhone;
      bool isEmail;

      if (_isPhoneLogin) {
        // Format phone number properly
        emailOrPhone =
            completePhoneNumber ?? '${phoneCode}${_phoneController.text}';
        // Simple phone formatting - remove spaces and ensure format
        emailOrPhone = emailOrPhone.replaceAll(' ', '').replaceAll('-', '');
        isEmail = false;

        // Additional validation for phone
        if (emailOrPhone.isEmpty || _phoneController.text.trim().isEmpty) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please enter a valid phone number'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      } else {
        emailOrPhone = _emailController.text.trim();
        isEmail = true;

        // Additional validation for email
        if (emailOrPhone.isEmpty) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please enter a valid email address'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      print('🔍 Attempting to check user existence for: $emailOrPhone');
      // NOTE: OTP flow now uses dedicated /send-email-otp or /send-phone-otp endpoints
      // via RestAuthService. Legacy otpToken-based path is deprecated.

      // Check if user exists via REST API
      try {
        final authService = RestAuthService.instance;
        final userExists = await authService.checkUserExists(emailOrPhone);

        setState(() {
          _isLoading = false;
        });

        if (userExists) {
          // Existing user - navigate to password screen
          print('✅ User exists - navigating to password screen');
          Navigator.pushNamed(
            context,
            '/password',
            arguments: {
              'isNewUser': false,
              'emailOrPhone': emailOrPhone,
              'isEmail': isEmail,
              'countryCode': widget.countryCode,
            },
          );
        } else {
          // New user - navigate to OTP screen for verification
          print('🆕 New user - navigating to OTP screen');
          Navigator.pushNamed(
            context,
            '/otp',
            arguments: {
              'isNewUser': true,
              'emailOrPhone': emailOrPhone,
              'isEmail': isEmail,
              'countryCode': widget.countryCode,
            },
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        print('❌ Error checking user existence: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to verify user. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
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

  // Removed _sendRegistrationOTP method - will be replaced with REST API flow

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
                      MediaQuery.of(context).padding.bottom -
                      48,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // Back button
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon:
                            const Icon(Icons.arrow_back, color: Colors.black87),
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
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: _isPhoneLogin
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Phone',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _isPhoneLogin
                                          ? Colors.white
                                          : Colors.grey[600],
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
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: !_isPhoneLogin
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Email',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: !_isPhoneLogin
                                          ? Colors.white
                                          : Colors.grey[600],
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
                                  ? Stack(
                                      children: [
                                        IntlPhoneField(
                                          key: const ValueKey('phone'),
                                          controller: _phoneController,
                                          decoration: const InputDecoration(
                                            labelText: 'Phone Number',
                                            prefixIcon: Icon(Icons.phone),
                                          ),
                                          initialCountryCode:
                                              widget.countryCode.isNotEmpty
                                                  ? widget.countryCode
                                                  : 'US',
                                          enabled: true,
                                          showCountryFlag: true,
                                          showDropdownIcon: false,
                                          disableLengthCheck: false,
                                          onChanged: (phone) {
                                            completePhoneNumber =
                                                phone.completeNumber;
                                          },
                                          validator: (phone) {
                                            if (phone == null ||
                                                phone.number.isEmpty) {
                                              return 'Please enter a valid phone number';
                                            }
                                            return null;
                                          },
                                        ),
                                        // Overlay to block country selector taps
                                        Positioned(
                                          left: 0,
                                          top: 0,
                                          bottom: 0,
                                          width:
                                              80, // Cover the country flag and code area
                                          child: Container(
                                            color: Colors.transparent,
                                          ),
                                        ),
                                      ],
                                    )
                                  : TextFormField(
                                      key: const ValueKey('email'),
                                      controller: _emailController,
                                      decoration: const InputDecoration(
                                        labelText: 'Email Address',
                                        prefixIcon: Icon(Icons.email),
                                      ),
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your email address';
                                        }
                                        if (!RegExp(
                                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                            .hasMatch(value)) {
                                          return 'Please enter a valid email address';
                                        }
                                        return null;
                                      },
                                    ),
                            ),
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
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : Text(
                                  _isPhoneLogin ? 'Send OTP' : 'Continue',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Terms text
                      Text.rich(
                        TextSpan(
                          text: 'By continuing, you agree to our ',
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 14),
                          children: [
                            TextSpan(
                              text: 'Terms of Service',
                              style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w600),
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w600),
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
                                style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w600),
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
