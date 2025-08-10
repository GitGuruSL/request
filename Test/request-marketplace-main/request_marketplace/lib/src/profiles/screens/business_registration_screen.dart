import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geo;
import '../../models/enhanced_user_model.dart';
import '../../services/user_profile_service.dart';
import '../../services/business_service.dart';

class BusinessRegistrationScreen extends StatefulWidget {
  final String userId;
  
  const BusinessRegistrationScreen({
    super.key,
    required this.userId,
  });

  @override
  State<BusinessRegistrationScreen> createState() => _BusinessRegistrationScreenState();
}

class _BusinessRegistrationScreenState extends State<BusinessRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _userProfileService = UserProfileService();
  final _businessService = BusinessService();
  final Location _location = Location();
  final _imagePicker = ImagePicker();

  BusinessType _selectedBusinessType = BusinessType.retail;
  final List<String> _selectedCategories = [];
  final List<File> _businessImages = [];
  final Map<String, String> _businessHours = {
    'Monday': 'Closed',
    'Tuesday': 'Closed',
    'Wednesday': 'Closed',
    'Thursday': 'Closed',
    'Friday': 'Closed',
    'Saturday': 'Closed',
    'Sunday': 'Closed',
  };
  
  double _latitude = 0.0;
  double _longitude = 0.0;
  bool _isLoading = false;
  bool _hasDocuments = false;

  final List<String> _businessCategories = [
    'Electronics', 'Clothing', 'Food & Beverages', 'Home & Garden',
    'Automotive', 'Health & Beauty', 'Sports', 'Books & Media',
    'Services', 'Construction', 'Technology', 'Education',
    'Entertainment', 'Travel', 'Finance', 'Real Estate'
  ];

  @override
  void initState() {
    super.initState();
    _checkExistingBusiness();
  }

  /// Check if user already has a business registered
  Future<void> _checkExistingBusiness() async {
    try {
      final existingBusiness = await _businessService.getUserBusiness(widget.userId);
      if (existingBusiness != null) {
        // User already has a business, show dialog and navigate back
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Business Already Registered'),
              content: Text(
                'You already have a registered business: "${existingBusiness.basicInfo.name}". '
                'Each user can only have one business registered.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Go back to profile
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      print('Error checking existing business: $e');
      // Continue with registration if there's an error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Business'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1D1B20),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Color(0xFF1D1B20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: const Color(0xFFFFFBFE),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6750A4), Color(0xFF9575CD)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.business, color: Colors.white, size: 32),
                    SizedBox(height: 16),
                    Text(
                      'Register Your Business',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Start selling products and reach more customers',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Debug Section (Remove in production)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.yellow.shade50,
                  border: Border.all(color: Colors.orange.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🐛 Debug Tools',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              print('🔍 Testing Firestore connection...');
                              try {
                                await FirebaseFirestore.instance
                                    .collection('test')
                                    .doc('connection')
                                    .set({'test': DateTime.now().toString()});
                                print('✅ Firestore connection successful');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✅ Firestore connection successful'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } catch (e) {
                                print('❌ Firestore connection failed: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('❌ Firestore connection failed: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            child: const Text('Test Firestore'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              print('👤 User ID: ${widget.userId}');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('👤 User ID: ${widget.userId}'),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            },
                            child: const Text('Show User ID'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Business Type (Moved to top)
              const Text(
                'Business Type',
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D1B20),
                ),
              ),
              const SizedBox(height: 16),

              // Business Type Dropdown
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonFormField<BusinessType>(
                  value: _selectedBusinessType,
                  decoration: const InputDecoration(
                    hintText: 'Select business type',
                    hintStyle: TextStyle(
                      color: Color(0xFF79747E),
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(Icons.category, color: Color(0xFF79747E)),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  items: BusinessType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getBusinessTypeDisplayName(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedBusinessType = value!;
                    });
                  },
                ),
              ),
              const SizedBox(height: 32),

              // Business Basic Info
              const Text(
                'Basic Information',
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D1B20),
                ),
              ),
              const SizedBox(height: 16),

              // Business Name
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextFormField(
                  controller: _businessNameController,
                  style: const TextStyle(
                    color: Color(0xFF1D1B20),
                    fontSize: 16,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Business Name *',
                    hintStyle: TextStyle(
                      color: Color(0xFF79747E),
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(Icons.store, color: Color(0xFF79747E)),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your business name';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Business Email
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(
                    color: Color(0xFF1D1B20),
                    fontSize: 16,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Business Email *',
                    hintStyle: TextStyle(
                      color: Color(0xFF79747E),
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF79747E)),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Business email is required';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Phone Number
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextFormField(
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(
                    color: Color(0xFF1D1B20),
                    fontSize: 16,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Phone Number *',
                    hintStyle: TextStyle(
                      color: Color(0xFF79747E),
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(Icons.phone, color: Color(0xFF79747E)),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Business Address
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextFormField(
                  controller: _addressController,
                  style: const TextStyle(
                    color: Color(0xFF1D1B20),
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Business Address *',
                    hintStyle: const TextStyle(
                      color: Color(0xFF79747E),
                      fontSize: 16,
                    ),
                    prefixIcon: const Icon(Icons.location_on, color: Color(0xFF79747E)),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.my_location, color: Color(0xFF79747E)),
                      onPressed: _getCurrentLocation,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your business address';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Business Categories
              const Text(
                'Business Categories',
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D1B20),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select categories that best describe your business',
                style: TextStyle(color: Color(0xFF49454F), fontSize: 14),
              ),
              const SizedBox(height: 16),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _businessCategories.map((category) {
                  final isSelected = _selectedCategories.contains(category);
                  return FilterChip(
                    label: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF6750A4) : const Color(0xFF49454F),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: _selectedCategories.length < 5 || isSelected
                        ? (selected) {
                            setState(() {
                              if (selected) {
                                _selectedCategories.add(category);
                              } else {
                                _selectedCategories.remove(category);
                              }
                            });
                          }
                        : null,
                    selectedColor: const Color(0xFF6750A4).withOpacity(0.12),
                    backgroundColor: Colors.white,
                    checkmarkColor: const Color(0xFF6750A4),
                    side: BorderSide.none,
                    elevation: 0,
                    pressElevation: 0,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Business Images
              const Text(
                'Business Images',
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D1B20),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add photos of your business, products, or services (up to 6 images)',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 16),
              
              if (_businessImages.isNotEmpty) ...[
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _businessImages.length + (_businessImages.length < 6 ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < _businessImages.length) {
                      return Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: FileImage(_businessImages[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
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
                      );
                    } else {
                      return GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, color: Colors.grey[600]),
                              const SizedBox(height: 4),
                              Text('Add More', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                ),
              ] else ...[
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey[600]),
                        const SizedBox(height: 8),
                        Text('Add Business Photos', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Legal Information (Optional)
              const Text(
                'Legal Information (Optional)',
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D1B20),
                ),
              ),
              const SizedBox(height: 16),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextFormField(
                  controller: _registrationNumberController,
                  style: const TextStyle(
                    color: Color(0xFF1D1B20),
                    fontSize: 16,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Business Registration Number',
                    hintStyle: TextStyle(
                      color: Color(0xFF79747E),
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(Icons.assignment, color: Color(0xFF79747E)),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextFormField(
                  controller: _taxIdController,
                  style: const TextStyle(
                    color: Color(0xFF1D1B20),
                    fontSize: 16,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Tax ID/VAT Number',
                    hintStyle: TextStyle(
                      color: Color(0xFF79747E),
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(Icons.account_balance, color: Color(0xFF79747E)),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Document Upload
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.file_upload, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            'Business Documents',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Upload business license, registration certificate, or other official documents to verify your business.',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        title: const Text('I have business documents to upload'),
                        value: _hasDocuments,
                        onChanged: (value) {
                          setState(() {
                            _hasDocuments = value ?? false;
                          });
                        },
                      ),
                      if (_hasDocuments)
                        ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Implement document upload
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Document upload coming soon!')),
                            );
                          },
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Upload Documents'),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitBusinessRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6750A4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Register Business',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Skip Option
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                  child: const Text(
                    'Skip for now - I\'ll complete this later',
                    style: TextStyle(color: Color(0xFF49454F)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  String _getBusinessTypeDisplayName(BusinessType type) {
    switch (type) {
      case BusinessType.retail:
        return 'Retail Store';
      case BusinessType.service:
        return 'Service Provider';
      case BusinessType.restaurant:
        return 'Restaurant/Food';
      case BusinessType.rental:
        return 'Rental Business';
      case BusinessType.logistics:
        return 'Delivery/Logistics';
      case BusinessType.professional:
        return 'Professional Services';
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) return;
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) return;
      }

      LocationData locationData = await _location.getLocation();
      List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
        locationData.latitude!,
        locationData.longitude!,
      );

      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks[0];
        final locationText = '${place.name}, ${place.locality}, ${place.administrativeArea}';
        setState(() {
          _addressController.text = locationText;
          _latitude = locationData.latitude!;
          _longitude = locationData.longitude!;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get location: $e')),
        );
      }
    }
  }

  Future<void> _pickImages() async {
    if (_businessImages.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 6 images allowed')),
      );
      return;
    }

    final pickedFiles = await _imagePicker.pickMultiImage(imageQuality: 80);
    if (pickedFiles.isNotEmpty) {
      setState(() {
        final remainingSlots = 6 - _businessImages.length;
        final imagesToAdd = pickedFiles.take(remainingSlots);
        _businessImages.addAll(imagesToAdd.map((xFile) => File(xFile.path)));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _businessImages.removeAt(index);
    });
  }

  Future<void> _submitBusinessRegistration() async {
    print('🚀 Starting business registration submission...');
    
    if (!_formKey.currentState!.validate()) {
      print('❌ Form validation failed');
      return;
    }

    if (_selectedCategories.isEmpty) {
      print('❌ No business categories selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one business category')),
      );
      return;
    }

    print('✅ Form validation passed');
    print('📝 Business Name: ${_businessNameController.text.trim()}');
    print('� Business Email: ${_emailController.text.trim()}');
    print('�📝 Business Type: $_selectedBusinessType');
    print('📝 Categories: $_selectedCategories');
    print('📝 Address: ${_addressController.text.trim()}');
    print('📍 Location: $_latitude, $_longitude');
    
    setState(() {
      _isLoading = true;
    });

    try {
      print('🏢 Creating business profile...');
      
      // Create business profile
      final businessProfile = BusinessProfile(
        businessName: _businessNameController.text.trim(),
        email: _emailController.text.trim(),
        businessType: _selectedBusinessType,
        businessRegistrationNumber: _registrationNumberController.text.trim().isNotEmpty 
            ? _registrationNumberController.text.trim() : null,
        taxId: _taxIdController.text.trim().isNotEmpty 
            ? _taxIdController.text.trim() : null,
        description: _descriptionController.text.trim(),
        businessCategories: _selectedCategories,
        businessHours: _businessHours,
        businessImages: [], // TODO: Upload images to storage first
        businessAddress: _addressController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        verificationStatus: VerificationStatus.pending,
        isActive: true,
      );

      print('🔄 Converting business profile to map...');
      final businessData = businessProfile.toMap();
      print('📄 Business data: $businessData');

      print('💾 Saving to Firestore...');
      // Add business profile to user
      await _userProfileService.addBusinessProfile(widget.userId, businessProfile);

      print('✅ Business registration successful!');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Business registered successfully! Verification pending.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Navigate back to previous screen or home
        print('🏠 Navigating back...');
        Navigator.pop(context, true); // Return success result
      }
    } catch (e, stackTrace) {
      print('❌ Business registration failed:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Error registering business:'),
                Text(
                  e.toString(),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
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
  void dispose() {
    _businessNameController.dispose();
    _emailController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _registrationNumberController.dispose();
    _taxIdController.dispose();
    super.dispose();
  }
}
