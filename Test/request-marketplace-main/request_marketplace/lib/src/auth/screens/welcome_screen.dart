import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:request_marketplace/src/auth/screens/login_screen.dart';
import 'package:request_marketplace/src/widgets/app_logo.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  Country? _selectedCountry;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBFE),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  // Top spacing - make it flexible
                  SizedBox(height: size.height * 0.06),
                  
                  // Logo
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: const AppLogo.large(),
                  ),
                  
                  SizedBox(height: size.height * 0.04),
                  
                  // Welcome content
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          const Text(
                            'Welcome to',
                            style: TextStyle(
                              color: Color(0xFF49454F),
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Request',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D1B20),
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Connect with local businesses and\nservice providers effortlessly',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF49454F),
                              height: 1.5,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Flexible spacer
                  SizedBox(height: size.height * 0.08),
                  
                  // Country selection
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Select your country',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1D1B20),
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () {
                                showCountryPicker(
                                  context: context,
                                  showPhoneCode: false,
                                  onSelect: (Country country) {
                                    setState(() {
                                      _selectedCountry = country;
                                    });
                                  },
                                  countryListTheme: const CountryListThemeData(
                                    borderRadius: BorderRadius.all(Radius.circular(16)),
                                    flagSize: 24,
                                    searchTextStyle: TextStyle(
                                      color: Color(0xFF1D1B20),
                                      fontSize: 16,
                                      fontFamily: 'Poppins',
                                    ),
                                    inputDecoration: InputDecoration(
                                      hintText: 'Search',
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    if (_selectedCountry != null) ...[
                                      Text(
                                        _selectedCountry!.flagEmoji,
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _selectedCountry!.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Color(0xFF1D1B20),
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                    ] else ...[
                                      const Expanded(
                                        child: Text(
                                          'Choose your country',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Color(0xFF79747E),
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                    ],
                                    const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: Color(0xFF49454F),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Continue button
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _selectedCountry == null
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation, secondaryAnimation) =>
                                          LoginScreen(countryCode: _selectedCountry!.countryCode),
                                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                        return SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(1.0, 0.0),
                                            end: Offset.zero,
                                          ).animate(CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeInOut,
                                          )),
                                          child: child,
                                        );
                                      },
                                      transitionDuration: const Duration(milliseconds: 300),
                                    ),
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6750A4),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Flexible bottom spacing
                  SizedBox(height: size.height * 0.04),
                  
                  // Powered by footer
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: const Text(
                      'Powered by Alphabet (Pvt) Ltd',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF79747E),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
