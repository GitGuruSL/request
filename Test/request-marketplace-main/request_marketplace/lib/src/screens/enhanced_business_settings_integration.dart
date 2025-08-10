import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/unified_otp_service.dart';
import '../../widgets/unified_otp_widget.dart';
import '../../models/business_models.dart';
import '../../services/business_service.dart';

/// Enhanced Business Settings Screen with Unified OTP Integration
/// 
/// This example shows how to integrate the unified OTP system
/// into the existing business settings screen for phone verification
class EnhancedBusinessSettingsScreen extends StatefulWidget {
  final String businessId;

  const EnhancedBusinessSettingsScreen({
    Key? key,
    required this.businessId,
  }) : super(key: key);

  @override
  State<EnhancedBusinessSettingsScreen> createState() => _EnhancedBusinessSettingsScreenState();
}

class _EnhancedBusinessSettingsScreenState extends State<EnhancedBusinessSettingsScreen> {
  final BusinessService _businessService = BusinessService();
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _businessNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  
  BusinessProfile? _business;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _showPhoneVerification = false;
  bool _phoneVerified = false;
  bool _emailVerified = false;

  @override
  void initState() {
    super.initState();
    _loadBusinessProfile();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadBusinessProfile() async {
    setState(() => _isLoading = true);

    try {
      final business = await _businessService.getBusinessProfile(widget.businessId);
      
      if (business != null) {
        setState(() {
          _business = business;
          _businessNameController.text = business.basicInfo.name;
          _descriptionController.text = business.basicInfo.description;
          _emailController.text = business.basicInfo.email;
          _addressController.text = business.basicInfo.address.fullAddress;
          
          // Phone number formatting
          String phoneNumber = business.basicInfo.phone;
          if (phoneNumber.startsWith('+94')) {
            phoneNumber = phoneNumber.substring(3).trim();
          }
          _phoneController.text = phoneNumber;
          
          // Verification status
          _phoneVerified = business.verification.isPhoneVerified;
          _emailVerified = business.verification.isEmailVerified;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error loading business profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveBusinessInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Format phone number
      String phoneNumber = _phoneController.text.trim();
      if (!phoneNumber.startsWith('+94')) {
        phoneNumber = '+94$phoneNumber';
      }

      // Update business info
      await FirebaseFirestore.instance
          .collection('businesses')
          .doc(widget.businessId)
          .update({
        'basicInfo.name': _businessNameController.text.trim(),
        'basicInfo.description': _descriptionController.text.trim(),
        'basicInfo.phone': phoneNumber,
        'basicInfo.email': _emailController.text.trim(),
        'basicInfo.address.street': _addressController.text.trim(),
        'updatedAt': Timestamp.now(),
      });

      await _loadBusinessProfile();
      _showSuccessSnackBar('Business information updated successfully');
    } catch (e) {
      _showErrorSnackBar('Error saving business info: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _startPhoneVerification() {
    setState(() => _showPhoneVerification = true);
  }

  void _onPhoneVerificationComplete(String phoneNumber, bool isVerified) {
    if (isVerified) {
      setState(() {
        _phoneVerified = true;
        _showPhoneVerification = false;
      });
      _showSuccessSnackBar('Phone number verified successfully!');
      
      // Reload business profile to update verification status
      _loadBusinessProfile();
    }
  }

  void _onPhoneVerificationError(String error) {
    _showErrorSnackBar('Phone verification error: $error');
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Settings'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Business Info Section
              _buildSectionCard(
                'Business Information',
                [
                  TextFormField(
                    controller: _businessNameController,
                    decoration: const InputDecoration(
                      labelText: 'Business Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Business name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Phone Verification Section
              _buildPhoneVerificationSection(),
              
              const SizedBox(height: 20),
              
              // Email Section
              _buildSectionCard(
                'Email Information',
                [
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Business Email',
                      border: const OutlineInputBorder(),
                      suffixIcon: _emailVerified
                          ? const Icon(Icons.verified, color: Colors.green)
                          : const Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Email is required';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  if (_emailVerified) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        border: Border.all(color: Colors.green[200]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Email verified',
                            style: TextStyle(color: Colors.green, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 30),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveBusinessInfo,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Business Information'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneVerificationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Phone Verification',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_phoneVerified)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, color: Colors.green[700], size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Verified',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (!_showPhoneVerification && !_phoneVerified) ...[
              // Phone input when not in verification mode
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Business Phone Number',
                  border: OutlineInputBorder(),
                  prefixText: '+94 ',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Phone number is required';
                  }
                  if (value!.length < 9) {
                    return 'Enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startPhoneVerification,
                  icon: const Icon(Icons.phone_android),
                  label: const Text('Verify Phone Number'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ] else if (_showPhoneVerification) ...[
              // Unified OTP Widget for verification
              UnifiedOtpWidget(
                context: UnifiedOtpService.VerificationContext.businessRegistration,
                userType: 'business',
                initialPhoneNumber: '+94${_phoneController.text}',
                title: 'Verify Business Phone',
                subtitle: 'Confirm your business contact number',
                showPhoneInput: false, // Phone already set above
                onVerificationComplete: _onPhoneVerificationComplete,
                onError: _onPhoneVerificationError,
                additionalData: {
                  'businessId': widget.businessId,
                  'businessName': _businessNameController.text,
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _showPhoneVerification = false),
                child: const Text('Cancel Verification'),
              ),
            ] else if (_phoneVerified) ...[
              // Verified state
              Container(
                padding: const EdgeInsets.all(16),
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
                            'Phone Number Verified',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                          Text(
                            '+94${_phoneController.text}',
                            style: TextStyle(
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _showPhoneVerification = true;
                        _phoneVerified = false;
                      }),
                      child: const Text('Change'),
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

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Integration Example for Login Screen
class EnhancedLoginScreen extends StatefulWidget {
  const EnhancedLoginScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedLoginScreen> createState() => _EnhancedLoginScreenState();
}

class _EnhancedLoginScreenState extends State<EnhancedLoginScreen> {
  void _onLoginVerificationComplete(String phoneNumber, bool isVerified) {
    if (isVerified) {
      // Handle successful login verification
      // Navigate to main app or profile completion
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login successful for $phoneNumber'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _onLoginVerificationError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Login error: $error'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login with Phone'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text(
              'Welcome Back',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: UnifiedOtpWidget(
                context: UnifiedOtpService.VerificationContext.login,
                title: 'Sign In with Phone',
                subtitle: 'Enter your phone number to continue',
                onVerificationComplete: _onLoginVerificationComplete,
                onError: _onLoginVerificationError,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Integration Example for Driver Registration
class EnhancedDriverRegistrationScreen extends StatefulWidget {
  const EnhancedDriverRegistrationScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedDriverRegistrationScreen> createState() => _EnhancedDriverRegistrationScreenState();
}

class _EnhancedDriverRegistrationScreenState extends State<EnhancedDriverRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _licenseController = TextEditingController();
  bool _phoneVerified = false;
  String? _verifiedPhone;

  void _onDriverPhoneVerificationComplete(String phoneNumber, bool isVerified) {
    setState(() {
      _phoneVerified = isVerified;
      _verifiedPhone = phoneNumber;
    });
    
    if (isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Driver phone verified: $phoneNumber'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _submitDriverRegistration() {
    if (!_formKey.currentState!.validate() || !_phoneVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all fields including phone verification'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Process driver registration with verified phone
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Driver registration submitted with verified phone: $_verifiedPhone'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Registration'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Driver info fields
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Name is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _licenseController,
                decoration: const InputDecoration(
                  labelText: 'License Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'License number is required';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // Phone verification
              UnifiedOtpWidget(
                context: UnifiedOtpService.VerificationContext.driverRegistration,
                userType: 'driver',
                title: 'Verify Driver Phone',
                subtitle: 'Confirm your contact number for driver services',
                onVerificationComplete: _onDriverPhoneVerificationComplete,
                onError: (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error), backgroundColor: Colors.red),
                  );
                },
                additionalData: {
                  'driverName': _nameController.text,
                  'licenseNumber': _licenseController.text,
                },
              ),
              
              const SizedBox(height: 30),
              
              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitDriverRegistration,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _phoneVerified 
                        ? Theme.of(context).primaryColor 
                        : Colors.grey,
                  ),
                  child: Text(
                    _phoneVerified 
                        ? 'Submit Driver Registration' 
                        : 'Verify Phone First',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
