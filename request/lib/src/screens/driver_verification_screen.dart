import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
// Removed firebase_shim after REST migration
import '../services/rest_auth_service.dart' hide UserModel;
// REMOVED_FB_IMPORT: import 'package:cloud_firestore/cloud_firestore.dart';
// REMOVED_FB_IMPORT: import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'dart:async';
import '../services/enhanced_user_service.dart';
import '../services/file_upload_service.dart';
import '../services/contact_verification_service.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';

class DriverVerificationScreen extends StatefulWidget {
  const DriverVerificationScreen({Key? key}) : super(key: key);

  @override
  State<DriverVerificationScreen> createState() =>
      _DriverVerificationScreenState();
}

class _DriverVerificationScreenState extends State<DriverVerificationScreen> {
  final EnhancedUserService _userService = EnhancedUserService();
  final FileUploadService _fileUploadService = FileUploadService();
  final ContactVerificationService _contactService =
      ContactVerificationService.instance;
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _fullNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _secondaryMobileController = TextEditingController();
  final _nicNumberController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _insuranceNumberController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehicleYearController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _vehicleColorController = TextEditingController();

  // New fields from mobile app
  DateTime? _dateOfBirth;
  String? _selectedGender;
  String? _selectedCity;
  bool _isVehicleOwner = true;
  bool _licenseHasNoExpiry = false;

  DateTime? _licenseExpiryDate;
  DateTime? _insuranceExpiryDate;

  // Vehicle type selection
  String? _selectedVehicleType;
  List<Map<String, dynamic>> _availableVehicleTypes = [];
  String? _userCountry;
  String? _userCountryPhoneCode; // Add country phone code

  // Cities selection
  List<Map<String, dynamic>> _availableCities = [];
  bool _loadingCities = false;

  // Document files
  File? _driverImage; // Driver's photo (Profile Photo)
  File? _licenseFrontPhoto; // License front photo
  File? _licenseBackPhoto; // License back photo
  File? _licenseDocument; // Additional license document (optional)
  File? _nicFrontPhoto; // NIC Front photo
  File? _nicBackPhoto; // NIC Back photo
  File? _billingProofDocument; // Billing Proof (optional)
  File? _insuranceDocument; // Vehicle insurance document
  File? _vehicleRegistrationDocument; // Vehicle registration document
  List<File> _vehicleImages = []; // Vehicle photos (4 images)

  bool _isLoading = false;

  // OTP Verification variables
  TextEditingController _phoneOtpController = TextEditingController();
  String? _phoneVerificationId;
  bool _isVerifyingPhone = false;
  bool _isPhoneVerified = false;
  bool _isPhoneOtpSent = false;
  bool _isVerifyingPhoneOtp = false;
  int _otpCountdown = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _userService.getCurrentUserModel();
      if (user != null && mounted) {
        setState(() {
          _fullNameController.text = user.name;

          // Auto-populate first name and last name from user data
          // If not available, try to split the display name
          if (user.firstName != null && user.firstName!.isNotEmpty) {
            _firstNameController.text = user.firstName!;
          } else if (user.name.isNotEmpty) {
            // Try to split display name into first and last names
            final nameParts = user.name.split(' ');
            _firstNameController.text = nameParts.first;
          }

          if (user.lastName != null && user.lastName!.isNotEmpty) {
            _lastNameController.text = user.lastName!;
          } else if (user.name.split(' ').length > 1) {
            // Use remaining parts as last name
            final nameParts = user.name.split(' ');
            _lastNameController.text = nameParts.skip(1).join(' ');
          }

          _phoneController.text = user.phoneNumber ?? '';
          _userCountry =
              user.countryCode ?? 'LK'; // Default to Sri Lanka if not set
        });

        // Load country phone code
        await _loadCountryPhoneCode();

        // Load available vehicle types for user's country
        await _loadAvailableVehicleTypes();

        // Load available cities for user's country
        await _loadAvailableCities();
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadCountryPhoneCode() async {
    try {
      // For now, use a simple mapping. In a real app, you might fetch this from an API
      final phoneCodeMap = {
        'LK': '+94', // Sri Lanka
        'US': '+1', // United States
        'IN': '+91', // India
        'UK': '+44', // United Kingdom
        'AU': '+61', // Australia
        'CA': '+1', // Canada
        'SG': '+65', // Singapore
        'MY': '+60', // Malaysia
        'TH': '+66', // Thailand
        'AE': '+971', // UAE
        'PH': '+63', // Philippines
        'ID': '+62', // Indonesia
        'VN': '+84', // Vietnam
        'BD': '+880', // Bangladesh
        'PK': '+92', // Pakistan
        'NP': '+977', // Nepal
        'JP': '+81', // Japan
        'KR': '+82', // South Korea
        'CN': '+86', // China
        'DE': '+49', // Germany
        'FR': '+33', // France
        'IT': '+39', // Italy
        'ES': '+34', // Spain
        'NL': '+31', // Netherlands
        'BR': '+55', // Brazil
        'AR': '+54', // Argentina
        'CL': '+56', // Chile
        'MX': '+52', // Mexico
      };

      setState(() {
        _userCountryPhoneCode = phoneCodeMap[_userCountry ?? 'LK'] ?? '+94';
      });
    } catch (e) {
      print('Error loading country phone code: $e');
      setState(() {
        _userCountryPhoneCode = '+94'; // Default to Sri Lanka
      });
    }
  }

  Future<void> _loadAvailableVehicleTypes() async {
    // Stubbed vehicle types until REST endpoint implemented
    if (mounted) {
      setState(() {
        _availableVehicleTypes = [
          {
            'id': 'car',
            'name': 'Car',
            'icon': 'DirectionsCar',
            'displayOrder': 1
          },
          {
            'id': 'motorcycle',
            'name': 'Motorcycle',
            'icon': 'TwoWheeler',
            'displayOrder': 2
          },
        ];
        if (_selectedVehicleType == null && _availableVehicleTypes.isNotEmpty) {
          _selectedVehicleType = _availableVehicleTypes.first['id'];
        }
      });
    }
  }

  Future<void> _loadAvailableCities() async {
    try {
      setState(() {
        _loadingCities = true;
      });

      final countryCode = _userCountry ?? 'LK';
      final response = await ApiClient.instance.get(
        '/api/cities',
        queryParameters: {'country': countryCode},
      );

      if (response.data['success'] == true) {
        final cities = (response.data['data'] as List)
            .map((city) => {
                  'id': city['id']?.toString() ?? city['name'],
                  'name': city['name'] as String,
                  'countryCode': city['countryCode'] ?? countryCode,
                })
            .where((city) => city['name']?.isNotEmpty == true)
            .toList();

        if (mounted) {
          setState(() {
            _availableCities = cities.isNotEmpty
                ? cities
                : [
                    {
                      'id': 'no_cities',
                      'name': 'No cities available',
                      'countryCode': countryCode
                    }
                  ];
            _loadingCities = false;
          });
        }
      } else {
        throw Exception('API returned success: false');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading cities: $e');
      if (mounted) {
        setState(() {
          _availableCities = [
            {
              'id': 'error',
              'name': 'Network error - try again',
              'countryCode': _userCountry ?? 'LK'
            }
          ];
          _loadingCities = false;
        });
      }
    }
  }

  Future<void> _selectDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime(now.year - 18, now.month, now.day),
    );
    if (picked != null && mounted) {
      setState(() => _dateOfBirth = picked);
    }
  }

  void _showDocumentRequirementsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Required Documents'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('• National Identity Card'),
            Text('• No Objection Certificate (if not vehicle owner)'),
            Text('• Vehicle Owner\'s National Identity Card (if applicable)'),
            Text('• Billing Proof (Utility bill or bank statement)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _licenseNumberController.dispose();
    _insuranceNumberController.dispose();
    _vehicleModelController.dispose();
    _vehicleYearController.dispose();
    _vehicleNumberController.dispose();
    _vehicleColorController.dispose();
    _phoneOtpController.dispose();
    super.dispose();
  }

  // Check if phone number needs OTP verification
  bool _isPhoneVerifiedByFirebase() {
    final currentUser = RestAuthService.instance.currentUser;
    if (currentUser?.phoneNumber == null || _phoneController.text.isEmpty) {
      return false;
    }

    // Clean both phone numbers for comparison
    String firebasePhone =
        currentUser!.phoneNumber!.replaceAll(' ', '').replaceAll('-', '');
    String enteredPhone =
        _phoneController.text.replaceAll(' ', '').replaceAll('-', '');

    // Remove country codes for comparison if present
    if (firebasePhone.startsWith('+94'))
      firebasePhone = firebasePhone.substring(3);
    if (enteredPhone.startsWith('+94'))
      enteredPhone = enteredPhone.substring(3);
    if (firebasePhone.startsWith('94'))
      firebasePhone = firebasePhone.substring(2);
    if (enteredPhone.startsWith('94')) enteredPhone = enteredPhone.substring(2);

    return firebasePhone == enteredPhone;
  }

  // OTP Countdown timer
  void _startOtpCountdown() {
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_otpCountdown > 0) {
          _otpCountdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Driver Verification'),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDriverInformation(),
              const SizedBox(height: 24),
              _buildDocumentsSection(),
              const SizedBox(height: 24),
              _buildVehicleInformation(),
              const SizedBox(height: 24),
              _buildVehicleDocuments(),
              const SizedBox(height: 24),
              _buildVehicleImages(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to get vehicle icon based on icon name
  Widget _getVehicleIcon(String iconName) {
    IconData iconData;
    switch (iconName) {
      case 'DirectionsCar':
        iconData = Icons.directions_car;
        break;
      case 'TwoWheeler':
        iconData = Icons.two_wheeler;
        break;
      case 'LocalShipping':
        iconData = Icons.local_shipping;
        break;
      case 'DirectionsBus':
        iconData = Icons.directions_bus;
        break;
      case 'Motorcycle':
        iconData = Icons.motorcycle;
        break;
      case 'LocalTaxi':
        iconData = Icons.local_taxi;
        break;
      case 'AirportShuttle':
        iconData = Icons.airport_shuttle;
        break;
      default:
        iconData = Icons.directions_car;
    }
    return Icon(iconData, size: 20);
  }

  Widget _buildDriverInformation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 12),
              const Text(
                'About You',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _firstNameController,
                  readOnly: true, // Auto-populated from user account
                  decoration: const InputDecoration(
                    labelText: 'First Name * (from account)',
                    prefixIcon: Icon(Icons.person_outline),
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Color(
                        0xFFF5F5F5), // Slightly grayed to indicate read-only
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'First name is required. Please update your account profile.';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _lastNameController,
                  readOnly: true, // Auto-populated from user account
                  decoration: const InputDecoration(
                    labelText: 'Last Name * (from account)',
                    prefixIcon: Icon(Icons.person_outline),
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Color(
                        0xFFF5F5F5), // Slightly grayed to indicate read-only
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Last name is required. Please update your account profile.';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _selectDateOfBirth,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today),
                  const SizedBox(width: 12),
                  Text(
                    _dateOfBirth == null
                        ? 'Date of Birth *'
                        : 'Date of Birth: ${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}',
                    style: TextStyle(
                      color: _dateOfBirth == null
                          ? Colors.grey[600]
                          : Colors.black,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(
                labelText: 'Gender *',
                prefixIcon: Icon(Icons.person),
                border: InputBorder.none,
              ),
              items: const [
                DropdownMenuItem(value: 'Male', child: Text('Male')),
                DropdownMenuItem(value: 'Female', child: Text('Female')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedGender = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select your gender';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nicNumberController,
            decoration: const InputDecoration(
              labelText: 'NIC Number *',
              prefixIcon: Icon(Icons.credit_card),
              border: InputBorder.none,
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your NIC number';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          // Contact Details Section
          Row(
            children: [
              Icon(Icons.contact_phone, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Contact Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Phone Verification Section - Auto or Manual based on Firebase verification
          _isPhoneVerifiedByFirebase()
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Phone Number (Auto-Verified)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _phoneController.text.isNotEmpty
                            ? _phoneController.text
                            : 'No phone number',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'This number was verified during account creation',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    // Removed border and shadow as requested
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Phone Verification Required',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _phoneController.text.isNotEmpty
                            ? _phoneController.text
                            : 'Phone number required for driver registration',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: _phoneController.text.isEmpty
                              ? Colors.red[700]
                              : AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Dynamic message based on phone number availability
                      Text(
                        _phoneController.text.isEmpty
                            ? 'Please enter your phone number below. This is required for driver verification.'
                            : 'This number is different from your account phone. Please verify:',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Phone Number Input Field (when no phone number is available)
                      if (_phoneController.text.isEmpty) ...[
                        TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: 'Phone Number *',
                            hintText: 'Enter your phone number',
                            prefixIcon: Icon(Icons.phone),
                            prefixText:
                                '${_userCountryPhoneCode ?? '+94'} ', // Show country code
                            border: OutlineInputBorder(),
                            helperText:
                                'This number will be used for driver verification',
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Phone number is required for driver registration';
                            }
                            // Basic phone number validation
                            final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
                            if (!phoneRegex.hasMatch(
                                value.replaceAll(RegExp(r'[\s\-\(\)]'), ''))) {
                              return 'Please enter a valid phone number';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            setState(() {
                              // Reset verification status when phone number changes
                              _isPhoneVerified = false;
                              _isPhoneOtpSent = false;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Show current phone number if available but not verified
                      if (_phoneController.text.isNotEmpty &&
                          !_isPhoneVerifiedByFirebase()) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: Colors.blue.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Phone Number to Verify:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _phoneController.text,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // OTP Verification UI
                      if (!_isPhoneVerified &&
                          !_isPhoneOtpSent &&
                          _phoneController.text.isNotEmpty) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isVerifyingPhone
                                ? null
                                : () => _startPhoneVerification(
                                    _phoneController.text),
                            icon: _isVerifyingPhone
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white)))
                                : Icon(Icons.send),
                            label: Text(_isVerifyingPhone
                                ? 'Sending OTP...'
                                : 'Send OTP'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],

                      if (_isPhoneOtpSent && !_isPhoneVerified) ...[
                        TextFormField(
                          controller: _phoneOtpController,
                          decoration: InputDecoration(
                            labelText: 'Enter OTP',
                            hintText: 'Enter the 6-digit code',
                            prefixIcon: Icon(Icons.message),
                            border: OutlineInputBorder(),
                            counterText: _otpCountdown > 0
                                ? 'Resend in $_otpCountdown seconds'
                                : '',
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isVerifyingPhoneOtp
                                    ? null
                                    : _verifyPhoneOTP,
                                icon: _isVerifyingPhoneOtp
                                    ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white)))
                                    : Icon(Icons.verified),
                                label: Text(_isVerifyingPhoneOtp
                                    ? 'Verifying...'
                                    : 'Verify OTP'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (_otpCountdown == 0)
                              ElevatedButton(
                                onPressed: () => _startPhoneVerification(
                                    _phoneController.text),
                                child: Text('Resend'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 16),
                                ),
                              ),
                          ],
                        ),
                      ],

                      if (_isPhoneVerified) ...[
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green),
                              const SizedBox(width: 8),
                              Text(
                                'Phone number verified successfully!',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedCity,
              decoration: InputDecoration(
                labelText: 'City *',
                prefixIcon: const Icon(Icons.location_city),
                border: InputBorder.none,
                suffixIcon: _loadingCities
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
              items: _availableCities.map((city) {
                return DropdownMenuItem<String>(
                  value: city['name'],
                  child: Text(city['name']),
                );
              }).toList()
                ..add(const DropdownMenuItem(
                    value: 'other', child: Text('Other'))),
              onChanged: _loadingCities
                  ? null
                  : (value) {
                      setState(() {
                        _selectedCity = value;
                      });
                    },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select your city';
                }
                return null;
              },
              hint: _loadingCities
                  ? const Text('Loading cities...')
                  : const Text('Select your city'),
            ),
          ),
          const SizedBox(height: 24),
          // Vehicle Ownership Section
          Row(
            children: [
              Icon(Icons.directions_car,
                  color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Vehicle Ownership',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: Column(
              children: [
                RadioListTile<bool>(
                  title: const Text(
                      'I am the owner of this vehicle I am about to register.'),
                  value: true,
                  groupValue: _isVehicleOwner,
                  onChanged: (value) {
                    setState(() {
                      _isVehicleOwner = value!;
                    });
                  },
                  activeColor: AppTheme.primaryColor,
                ),
                RadioListTile<bool>(
                  title: const Text('I am not the owner of the vehicle.'),
                  value: false,
                  groupValue: _isVehicleOwner,
                  onChanged: (value) {
                    setState(() {
                      _isVehicleOwner = value!;
                    });
                  },
                  activeColor: AppTheme.primaryColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
            ),
            child: GestureDetector(
              onTap: () {
                _showDocumentRequirementsDialog();
              },
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'See list of documents required',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[800],
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _licenseNumberController,
            decoration: const InputDecoration(
              labelText: 'Driving License Number *',
              prefixIcon: Icon(Icons.credit_card),
              border: InputBorder.none,
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your license number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          if (!_licenseHasNoExpiry)
            GestureDetector(
              onTap: _selectLicenseExpiryDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 12),
                    Text(
                      _licenseExpiryDate == null
                          ? 'Expiration Date *'
                          : 'Expiration Date: ${_licenseExpiryDate!.day}/${_licenseExpiryDate!.month}/${_licenseExpiryDate!.year}',
                      style: TextStyle(
                        color: _licenseExpiryDate == null
                            ? Colors.grey[600]
                            : Colors.black,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
          if (!_licenseHasNoExpiry) const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: CheckboxListTile(
              title: const Text(
                'My licence does not have an expiry date. (for older licences)',
                style: TextStyle(fontSize: 14),
              ),
              value: _licenseHasNoExpiry,
              onChanged: (value) {
                setState(() {
                  _licenseHasNoExpiry = value!;
                  if (_licenseHasNoExpiry) {
                    _licenseExpiryDate = null;
                  }
                });
              },
              activeColor: AppTheme.primaryColor,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Personal Document Upload',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '* Required',
            style: TextStyle(
              fontSize: 12,
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          // Profile Photo Section
          Row(
            children: [
              Icon(Icons.person, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Profile Photo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildDocumentUpload(
            'Profile Photo',
            'Upload or capture your photo *',
            _driverImage,
            () => _pickDocument('driver_image'),
            Icons.person,
            isRequired: true,
          ),
          const SizedBox(height: 24),
          // Driving License Section
          Row(
            children: [
              Icon(Icons.credit_card, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Driving License',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildDocumentUpload(
            'Driving License - Front',
            'Upload or capture the front side of your driving license *',
            _licenseFrontPhoto,
            () => _pickDocument('license_front'),
            Icons.credit_card,
            isRequired: true,
          ),
          const SizedBox(height: 16),
          _buildDocumentUpload(
            'Driving License - Rear',
            'Upload or capture the back side of your driving license *',
            _licenseBackPhoto,
            () => _pickDocument('license_back'),
            Icons.flip_to_back,
            isRequired: true,
          ),
          const SizedBox(height: 24),
          // National Identity Card Section
          Row(
            children: [
              Icon(Icons.badge, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                'National Identity Card',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildDocumentUpload(
            'NIC - Front',
            'Upload or capture the front side of your National Identity Card',
            _nicFrontPhoto,
            () => _pickDocument('nic_front'),
            Icons.badge,
            isRequired: false,
          ),
          const SizedBox(height: 16),
          _buildDocumentUpload(
            'NIC - Rear',
            'Upload or capture the back side of your National Identity Card',
            _nicBackPhoto,
            () => _pickDocument('nic_back'),
            Icons.flip_to_back,
            isRequired: false,
          ),
          const SizedBox(height: 24),
          // Billing Proof Section
          Row(
            children: [
              Icon(Icons.receipt, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Billing Proof (optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildDocumentUpload(
            'Billing Proof',
            'Billing proof is used to confirm your address. It can be a utility bill (water, electricity or landline phone) or a bank statement with your correct address.',
            _billingProofDocument,
            () => _pickDocument('billing_proof'),
            Icons.receipt,
            isRequired: false,
          ),
          const SizedBox(height: 16),
          _buildInsuranceSection(),
        ],
      ),
    );
  }

  Widget _buildInsuranceSection() {
    return Column(
      children: [
        TextFormField(
          controller: _insuranceNumberController,
          decoration: const InputDecoration(
            labelText: 'Insurance Number *',
            prefixIcon: Icon(Icons.security),
            border: InputBorder.none,
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your insurance number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _selectInsuranceExpiryDate,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 12),
                Text(
                  _insuranceExpiryDate == null
                      ? 'Insurance Expiry Date *'
                      : 'Insurance Expiry: ${_insuranceExpiryDate!.day}/${_insuranceExpiryDate!.month}/${_insuranceExpiryDate!.year}',
                  style: TextStyle(
                    color: _insuranceExpiryDate == null
                        ? Colors.grey[600]
                        : Colors.black,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildDocumentUpload(
          'Vehicle Insurance Document',
          'Upload or capture your vehicle insurance certificate',
          _insuranceDocument,
          () => _pickDocument('vehicle_insurance'),
          Icons.security,
          isRequired: true,
        ),
        const SizedBox(height: 16),
        _buildDocumentUpload(
          'Vehicle Registration Document',
          'Upload or capture your vehicle registration document',
          _vehicleRegistrationDocument,
          () => _pickDocument('vehicle_registration'),
          Icons.assignment,
          isRequired: true,
        ),
      ],
    );
  }

  Widget _buildVehicleInformation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_car,
                  color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Vehicle Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Vehicle Type Selection
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.category, color: Colors.grey),
                    const SizedBox(width: 12),
                    const Text(
                      'Vehicle Type *',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_availableVehicleTypes.isEmpty)
                  const Text(
                    'Loading vehicle types...',
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  DropdownButtonFormField<String>(
                    value: _selectedVehicleType,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    items: _availableVehicleTypes.map((vehicle) {
                      return DropdownMenuItem<String>(
                        value: vehicle['id'],
                        child: Row(
                          children: [
                            _getVehicleIcon(vehicle['icon']),
                            const SizedBox(width: 8),
                            Text(vehicle['name']),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedVehicleType = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a vehicle type';
                      }
                      return null;
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _vehicleModelController,
            decoration: const InputDecoration(
              labelText: 'Vehicle Make & Model *',
              hintText: 'e.g., Toyota Camry',
              prefixIcon: Icon(Icons.directions_car),
              border: InputBorder.none,
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your vehicle make & model';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _vehicleYearController,
                  decoration: const InputDecoration(
                    labelText: 'Year *',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _vehicleColorController,
                  decoration: const InputDecoration(
                    labelText: 'Color *',
                    prefixIcon: Icon(Icons.color_lens),
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _vehicleNumberController,
            decoration: const InputDecoration(
              labelText: 'Vehicle Number/License Plate *',
              hintText: 'e.g., ABC-1234',
              prefixIcon: Icon(Icons.confirmation_number),
              border: InputBorder.none,
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your vehicle number';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleDocuments() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Vehicle Documents',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildVehicleImages() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_camera, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Vehicle Photos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Required: 4 vehicle photos (upload or capture)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[800],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '1. Front view with number plate visible',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange[700],
                        ),
                      ),
                      Text(
                        '2. Rear view with number plate visible',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange[700],
                        ),
                      ),
                      Text(
                        '3. & 4. Additional vehicle photos',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount:
                _vehicleImages.length < 6 ? _vehicleImages.length + 1 : 6,
            itemBuilder: (context, index) {
              if (index < _vehicleImages.length) {
                return _buildVehicleImageItem(index);
              } else {
                return _buildAddImageButton();
              }
            },
          ),
          if (_vehicleImages.length < 4) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Please upload at least ${4 - _vehicleImages.length} more photo(s)',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVehicleImageItem(int index) {
    String title = '';
    switch (index) {
      case 0:
        title = '1. Front View\n(with number plate)';
        break;
      case 1:
        title = '2. Rear View\n(with number plate)';
        break;
      default:
        title = '${index + 1}. Vehicle Photo';
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                  ),
                  child: Image.file(
                    _vehicleImages[index],
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _removeVehicleImage(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _pickVehicleImage,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          border: Border.all(
              color: Colors.grey[300]!, style: BorderStyle.solid, width: 2),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo,
              size: 40,
              color: Colors.grey,
            ),
            SizedBox(height: 8),
            Text(
              'Add Photo',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentUpload(String title, String description, File? file,
      VoidCallback onTap, IconData icon,
      {bool isRequired = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: file != null ? Colors.green.withOpacity(0.1) : Colors.white,
        ),
        child: Column(
          children: [
            Icon(
              file != null ? Icons.check_circle : icon,
              size: 40,
              color: file != null ? Colors.green : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              file != null ? '$title - Uploaded' : title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: file != null ? Colors.green : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              file != null ? 'Tap to change document' : description,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _canSubmit() ? _submitVerification : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const RoundedRectangleBorder(),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Submit for Verification',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  bool _canSubmit() {
    // Check if phone verification is required and completed
    bool phoneVerificationComplete =
        _isPhoneVerifiedByFirebase() || _isPhoneVerified;

    return _firstNameController.text.trim().isNotEmpty &&
        _lastNameController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty && // Phone number required
        phoneVerificationComplete && // Phone verification required
        _dateOfBirth != null &&
        _selectedGender != null &&
        _nicNumberController.text.trim().isNotEmpty &&
        _selectedCity != null &&
        _licenseNumberController.text.trim().isNotEmpty &&
        (_licenseExpiryDate != null || _licenseHasNoExpiry) &&
        _driverImage != null && // Driver photo required
        _licenseFrontPhoto != null && // License front photo required
        _licenseBackPhoto != null && // License back photo required
        _insuranceNumberController.text.trim().isNotEmpty &&
        _insuranceExpiryDate != null && // Insurance expiry date required
        _insuranceDocument != null && // Vehicle insurance required
        _vehicleModelController.text.trim().isNotEmpty &&
        _vehicleYearController.text.trim().isNotEmpty &&
        _vehicleColorController.text.trim().isNotEmpty &&
        _vehicleNumberController.text.trim().isNotEmpty &&
        _vehicleRegistrationDocument != null && // Vehicle registration required
        _vehicleImages.length >= 4 && // Minimum 4 vehicle photos
        !_isLoading;
  }

  // (Removed duplicate _loadAvailableCities and obsolete _buildDocumentListItem)

  Future<void> _selectLicenseExpiryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date != null) {
      setState(() => _licenseExpiryDate = date);
    }
  }

  Future<void> _selectInsuranceExpiryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date != null) {
      setState(() => _insuranceExpiryDate = date);
    }
  }

  Future<void> _pickDocument(String type) async {
    // Show dialog to choose between camera and gallery
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: const Text('Choose how you want to add the document:'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Camera'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            icon: const Icon(Icons.photo_library),
            label: const Text('Gallery'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1500,
      maxHeight: 1500,
    );

    if (image != null) {
      setState(() {
        switch (type) {
          case 'driver_image':
            _driverImage = File(image.path);
            break;
          case 'license_front':
            _licenseFrontPhoto = File(image.path);
            break;
          case 'license_back':
            _licenseBackPhoto = File(image.path);
            break;
          case 'license_document':
            _licenseDocument = File(image.path);
            break;
          case 'nic_front':
            _nicFrontPhoto = File(image.path);
            break;
          case 'nic_back':
            _nicBackPhoto = File(image.path);
            break;
          case 'billing_proof':
            _billingProofDocument = File(image.path);
            break;
          case 'vehicle_insurance':
            _insuranceDocument = File(image.path);
            break;
          case 'vehicle_registration':
            _vehicleRegistrationDocument = File(image.path);
            break;
        }
      });
    }
  }

  Future<void> _pickVehicleImage() async {
    if (_vehicleImages.length >= 6) return;

    // Show dialog to choose between camera and gallery
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Text(
          _vehicleImages.length < 2
              ? 'Photo ${_vehicleImages.length + 1}: ${_vehicleImages.length == 0 ? "Front view with number plate" : "Rear view with number plate"}'
              : 'Additional vehicle photo ${_vehicleImages.length + 1}',
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Camera'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            icon: const Icon(Icons.photo_library),
            label: const Text('Gallery'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1500,
      maxHeight: 1500,
    );

    if (image != null) {
      setState(() {
        _vehicleImages.add(File(image.path));
      });
    }
  }

  void _removeVehicleImage(int index) {
    setState(() {
      _vehicleImages.removeAt(index);
    });
  }

  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate() || !_canSubmit()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = await _userService.getCurrentUser();
      if (currentUser == null) throw Exception('User not authenticated');

      // Upload documents
      String? driverImageUrl,
          licenseFrontUrl,
          licenseBackUrl,
          licenseDocumentUrl,
          nicFrontUrl,
          nicBackUrl,
          billingProofUrl,
          insuranceUrl,
          registrationUrl;
      List<String> vehicleImageUrls = [];

      // Upload driver photo (required)
      if (_driverImage != null) {
        driverImageUrl = await _fileUploadService.uploadDriverDocument(
            currentUser.uid, _driverImage!, 'driver_photo');
      }

      // Upload license front photo (required)
      if (_licenseFrontPhoto != null) {
        licenseFrontUrl = await _fileUploadService.uploadDriverDocument(
            currentUser.uid, _licenseFrontPhoto!, 'license_front');
      }

      // Upload license back photo (required)
      if (_licenseBackPhoto != null) {
        licenseBackUrl = await _fileUploadService.uploadDriverDocument(
            currentUser.uid, _licenseBackPhoto!, 'license_back');
      }

      // Upload additional license document (optional)
      if (_licenseDocument != null) {
        licenseDocumentUrl = await _fileUploadService.uploadDriverDocument(
            currentUser.uid, _licenseDocument!, 'license_document');
      }

      // Upload NIC front photo (optional)
      if (_nicFrontPhoto != null) {
        nicFrontUrl = await _fileUploadService.uploadDriverDocument(
            currentUser.uid, _nicFrontPhoto!, 'nic_front');
      }

      // Upload NIC back photo (optional)
      if (_nicBackPhoto != null) {
        nicBackUrl = await _fileUploadService.uploadDriverDocument(
            currentUser.uid, _nicBackPhoto!, 'nic_back');
      }

      // Upload billing proof document (optional)
      if (_billingProofDocument != null) {
        billingProofUrl = await _fileUploadService.uploadDriverDocument(
            currentUser.uid, _billingProofDocument!, 'billing_proof');
      }

      // Upload license front photo (required)
      if (_licenseFrontPhoto != null) {
        licenseFrontUrl = await _fileUploadService.uploadDriverDocument(
            currentUser.uid, _licenseFrontPhoto!, 'license_front');
      }

      // Upload license back photo (required)
      if (_licenseBackPhoto != null) {
        licenseBackUrl = await _fileUploadService.uploadDriverDocument(
            currentUser.uid, _licenseBackPhoto!, 'license_back');
      }

      // Upload additional license document (optional)
      if (_licenseDocument != null) {
        licenseDocumentUrl = await _fileUploadService.uploadDriverDocument(
            currentUser.uid, _licenseDocument!, 'license_document');
      }

      // Upload vehicle insurance document (required)
      if (_insuranceDocument != null) {
        insuranceUrl = await _fileUploadService.uploadDriverDocument(
            currentUser.uid, _insuranceDocument!, 'vehicle_insurance');
      }

      // Upload vehicle registration document (required)
      if (_vehicleRegistrationDocument != null) {
        registrationUrl = await _fileUploadService.uploadDriverDocument(
            currentUser.uid,
            _vehicleRegistrationDocument!,
            'vehicle_registration');
      }

      // Upload vehicle images
      for (int i = 0; i < _vehicleImages.length; i++) {
        final imageUrl = await _fileUploadService.uploadVehicleImage(
            currentUser.uid, _vehicleImages[i], i + 1);
        vehicleImageUrls.add(imageUrl);
      }

      // Create driver verification data
      final driverData = {
        'userId': currentUser.uid,
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'fullName':
            '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        'email': currentUser.email,
        'phoneNumber': _phoneController.text.trim(),
        'phoneVerified': _isPhoneVerifiedByFirebase() ? true : _isPhoneVerified,
        'phoneVerificationSource':
            _isPhoneVerifiedByFirebase() ? 'firebase_auth' : 'otp_verification',
        'secondaryMobile': _secondaryMobileController.text.trim().isNotEmpty
            ? _secondaryMobileController.text.trim()
            : null,
        'dateOfBirth': _dateOfBirth,
        'gender': _selectedGender,
        'nicNumber': _nicNumberController.text.trim(),
        'city': _selectedCity,
        'isVehicleOwner': _isVehicleOwner,
        'licenseNumber': _licenseNumberController.text.trim(),
        'licenseExpiry': _licenseHasNoExpiry ? null : _licenseExpiryDate,
        'licenseHasNoExpiry': _licenseHasNoExpiry,
        'insuranceNumber': _insuranceNumberController.text.trim(),
        'insuranceExpiry': _insuranceExpiryDate,
        'vehicleModel': _vehicleModelController.text.trim(),
        'vehicleYear': int.parse(_vehicleYearController.text.trim()),
        'vehicleColor': _vehicleColorController.text.trim(),
        'vehicleNumber': _vehicleNumberController.text.trim(),
        'vehicleType': _selectedVehicleType ?? 'car',
        'country': _userCountry,
        'status': 'pending',
        'isVerified': false,
        'isActive': true,
        'availability': true,
        'rating': 0.0,
        'totalRides': 0,
        'totalEarnings': 0.0,
        'subscriptionPlan': 'free',
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),

        // Document URLs
        'driverImageUrl': driverImageUrl, // Driver photo (profile photo)
        'licenseFrontUrl': licenseFrontUrl, // License front photo
        'licenseBackUrl': licenseBackUrl, // License back photo
        'licenseDocumentUrl':
            licenseDocumentUrl, // Additional license document (optional)
        'nicFrontUrl': nicFrontUrl, // NIC front photo (optional)
        'nicBackUrl': nicBackUrl, // NIC back photo (optional)
        'billingProofUrl': billingProofUrl, // Billing proof (optional)
        'insuranceDocumentUrl': insuranceUrl, // Vehicle insurance
        'vehicleRegistrationUrl': registrationUrl, // Vehicle registration
        'vehicleImageUrls': vehicleImageUrls,

        // Verification status for each document/image
        'documentVerification': {
          'driverImage': {
            'status': 'pending',
            'submittedAt': DateTime.now()
          }, // Driver photo
          'licenseFront': {
            'status': 'pending',
            'submittedAt': DateTime.now()
          }, // License front
          'licenseBack': {
            'status': 'pending',
            'submittedAt': DateTime.now()
          }, // License back
          'licenseDocument': licenseDocumentUrl != null
              ? {'status': 'pending', 'submittedAt': DateTime.now()}
              : null, // Optional: License document
          'nicFront': nicFrontUrl != null
              ? {'status': 'pending', 'submittedAt': DateTime.now()}
              : null, // Optional: NIC front
          'nicBack': nicBackUrl != null
              ? {'status': 'pending', 'submittedAt': DateTime.now()}
              : null, // Optional: NIC back
          'billingProof': billingProofUrl != null
              ? {'status': 'pending', 'submittedAt': DateTime.now()}
              : null, // Optional: Billing proof
          'vehicleInsurance': {
            'status': 'pending',
            'submittedAt': DateTime.now()
          }, // Vehicle insurance
          'vehicleRegistration': {
            'status': 'pending',
            'submittedAt': DateTime.now()
          }, // Vehicle registration
        },
        'vehicleImageVerification': _vehicleImages
            .asMap()
            .entries
            .map((entry) => {
                  'imageIndex': entry.key,
                  'status': 'pending',
                  'submittedAt': DateTime.now(),
                  'imageType': entry.key == 0
                      ? 'front_with_plate'
                      : entry.key == 1
                          ? 'rear_with_plate'
                          : 'additional',
                })
            .toList(),
      };

      // Save to Firestore
      await _userService.submitDriverVerification(driverData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Driver verification submitted successfully! We\'ll review your documents within 1-3 business days.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting verification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Phone Verification Methods
  Future<void> _startPhoneVerification(String phoneNumber) async {
    print('DEBUG: Starting phone verification for: $phoneNumber');
    setState(() {
      _isVerifyingPhone = true;
      _phoneVerificationId = null;
      _isPhoneOtpSent = false;
    });

    try {
      print(
          'DEBUG: Calling ContactVerificationService.startBusinessPhoneVerification for driver');
      final result = await _contactService.startBusinessPhoneVerification(
        phoneNumber: phoneNumber,
        onCodeSent: (verificationId) {
          print(
              'DEBUG: SMS code sent successfully. VerificationId: $verificationId');
          if (mounted) {
            setState(() {
              _phoneVerificationId = verificationId;
              _isVerifyingPhone = false;
              _isPhoneOtpSent = true;
              _otpCountdown = 60; // Start 60 second countdown
            });

            // Start countdown timer
            _startOtpCountdown();

            // Show different message for development mode
            String message;
            if (verificationId.startsWith('dev_verification_')) {
              message = '🚀 DEVELOPMENT MODE: Use OTP code 123456 to verify';
            } else {
              message =
                  'SMS sent to $phoneNumber! Check your messages for the 6-digit code.';
            }
            _showSnackBar(message, isError: false);
          }
        },
        onError: (error) {
          print('DEBUG: Phone verification error: $error');
          if (mounted) {
            setState(() {
              _isVerifyingPhone = false;
            });
            _showSnackBar(error, isError: true);
          }
        },
      );

      if (!result.success && mounted) {
        setState(() {
          _isVerifyingPhone = false;
        });
        _showSnackBar(result.error ?? 'Failed to send SMS', isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifyingPhone = false;
        });
        _showSnackBar('Error: $e', isError: true);
      }
    }
  }

  Future<void> _verifyPhoneOTP() async {
    if (_phoneVerificationId == null ||
        _phoneOtpController.text.trim().isEmpty) {
      _showSnackBar('Please enter the OTP', isError: true);
      return;
    }

    setState(() {
      _isVerifyingPhoneOtp = true;
    });

    try {
      final result = await _contactService.verifyBusinessPhoneOTP(
        verificationId: _phoneVerificationId!,
        otp: _phoneOtpController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isVerifyingPhoneOtp = false;
        });

        if (result.success) {
          _showSnackBar('Phone number verified successfully!', isError: false);
          _phoneOtpController.clear();
          setState(() {
            _phoneVerificationId = null;
            _isPhoneVerified = true;
            _isPhoneOtpSent = false;
          });
        } else if (result.isCredentialConflict) {
          _showSnackBar(
            'This phone number is linked to another account. Please contact support.',
            isError: true,
          );
        } else {
          _showSnackBar(result.error ?? 'Verification failed', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifyingPhoneOtp = false;
        });
        _showSnackBar('Error verifying OTP: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 4 : 3),
      ),
    );
  }
}
