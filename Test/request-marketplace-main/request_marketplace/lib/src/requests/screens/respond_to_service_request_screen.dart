import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../../models/request_model.dart';
import '../../services/response_service.dart';
import '../../services/image_service.dart';
import '../../services/enhanced_driver_service.dart';
import '../../models/enhanced_driver_model.dart';
import '../../core/services/phone_verification_helper.dart';
import '../../profile/screens/phone_number_management_screen.dart';
import '../../theme/app_theme.dart';
import '../../drivers/screens/enhanced_driver_dashboard_screen.dart';
import '../../drivers/screens/driver_dashboard_screen.dart';
import '../../drivers/screens/driver_profile_debug_screen.dart';

enum ServiceExperience { beginner, intermediate, expert, professional }
enum AvailabilityType { immediate, withinWeek, flexible, scheduled }

class RespondToServiceRequestScreen extends StatefulWidget {
  final RequestModel request;

  const RespondToServiceRequestScreen({super.key, required this.request});

  @override
  State<RespondToServiceRequestScreen> createState() => _RespondToServiceRequestScreenState();
}

class _RespondToServiceRequestScreenState extends State<RespondToServiceRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _priceController = TextEditingController();
  final _experienceYearsController = TextEditingController();
  final _certificationController = TextEditingController();
  final ResponseService _responseService = ResponseService();
  final ImageService _imageService = ImageService();
  final EnhancedDriverService _enhancedDriverService = EnhancedDriverService();
  final ImagePicker _picker = ImagePicker();
  
  bool _isSubmitting = false;
  final List<File> _selectedImages = [];
  final List<String> _existingImageUrls = [];
  final Set<String> _selectedPhoneNumbers = {};
  List<dynamic> _userPhoneNumbers = [];
  
  // Enhanced driver verification status
  EnhancedDriverModel? _driverProfile;
  bool _isLoadingDriverProfile = true;
  
  // Service-specific fields
  ServiceExperience _experienceLevel = ServiceExperience.intermediate;
  AvailabilityType _availabilityType = AvailabilityType.flexible;
  bool _hasLicense = false;
  bool _hasInsurance = false;
  bool _isRemoteService = false;
  bool _canProvideOnsite = true;
  DateTime? _earliestAvailableDate;
  TimeOfDay? _preferredStartTime;
  TimeOfDay? _preferredEndTime;
  String? _selectedLocation;
  double? _latitude;
  double? _longitude;
  
  // Check if user has already responded
  bool _hasAlreadyResponded = false;
  bool _isLoadingExistingResponse = true;

  @override
  void initState() {
    super.initState();
    _checkExistingResponse();
    _loadEnhancedDriverProfile();
  }

  Future<void> _loadEnhancedDriverProfile() async {
    try {
      final driverProfile = await _enhancedDriverService.getDriverProfile();
      if (mounted) {
        setState(() {
          _driverProfile = driverProfile;
          _isLoadingDriverProfile = false;
        });
      }
    } catch (e) {
      print('Error loading enhanced driver profile: $e');
      if (mounted) {
        setState(() {
          _isLoadingDriverProfile = false;
        });
      }
    }
  }

  Future<void> _checkExistingResponse() async {
    try {
      print('🔍 Checking existing response for request: ${widget.request.id}');
      print('🔍 Current user ID: ${FirebaseAuth.instance.currentUser?.uid}');
      
      final hasResponded = await _responseService.hasUserAlreadyResponded(widget.request.id);
      
      if (mounted) {
        setState(() {
          _hasAlreadyResponded = hasResponded;
          _isLoadingExistingResponse = false;
        });
        
        print('✅ Response check complete: hasResponded = $hasResponded');
        print('✅ _hasAlreadyResponded set to: $_hasAlreadyResponded');
        
        if (hasResponded) {
          print('🔍 Loading existing response data...');
          final existingResponse = await _responseService.getUserExistingResponse(widget.request.id);
          if (existingResponse != null && mounted) {
            print('✅ Found existing response, populating form fields');
            setState(() {
              _messageController.text = existingResponse.message;
              _priceController.text = existingResponse.offeredPrice?.toString() ?? '';
              _selectedPhoneNumbers.clear();
              _selectedPhoneNumbers.addAll(existingResponse.sharedPhoneNumbers);
              _selectedLocation = existingResponse.location;
              _latitude = existingResponse.latitude;
              _longitude = existingResponse.longitude;
              
              if (existingResponse.images.isNotEmpty) {
                _existingImageUrls.clear();
                _existingImageUrls.addAll(existingResponse.images);
              }
            });
          } else {
            print('❌ Could not load existing response data');
          }
        }
      }
    } catch (e) {
      print('❌ Error checking existing response: $e');
      if (mounted) {
        setState(() {
          _isLoadingExistingResponse = false;
        });
      }
    }
  }



  Future<void> _pickImages() async {
    if (_selectedImages.length >= 6) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 6 images allowed for service responses')),
      );
      return;
    }

    final pickedFiles = await _picker.pickMultiImage(imageQuality: 80);
    if (pickedFiles.isNotEmpty) {
      setState(() {
        final remainingSlots = 6 - _selectedImages.length;
        final imagesToAdd = pickedFiles.take(remainingSlots);
        _selectedImages.addAll(imagesToAdd.map((xFile) => File(xFile.path)));
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _earliestAvailableDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (selectedDate != null) {
      setState(() {
        _earliestAvailableDate = selectedDate;
      });
    }
  }

  Future<void> _selectTime(bool isStartTime) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: isStartTime 
          ? (_preferredStartTime ?? const TimeOfDay(hour: 9, minute: 0))
          : (_preferredEndTime ?? const TimeOfDay(hour: 17, minute: 0)),
    );

    if (selectedTime != null) {
      setState(() {
        if (isStartTime) {
          _preferredStartTime = selectedTime;
        } else {
          _preferredEndTime = selectedTime;
        }
      });
    }
  }

  Future<void> _loadUserPhoneNumbers() async {
    try {
      final phoneNumbers = await PhoneVerificationHelper.getAllPhoneNumbers();
      if (mounted) {
        setState(() {
          _userPhoneNumbers = phoneNumbers.map((phone) => {
            'number': phone.number,
            'isVerified': phone.isVerified,
            'isPrimary': false, // Default to false, can be enhanced later
          }).toList();
        });
      }
    } catch (e) {
      print('Error loading user phone numbers: $e');
      if (mounted) {
        setState(() {
          _userPhoneNumbers = [];
        });
      }
    }
  }

  Future<void> _submitResponse() async {
    // Check phone verification before proceeding
    final hasVerifiedPhone = await PhoneVerificationHelper.validatePhoneVerification(context);
    if (!hasVerifiedPhone) {
      return; // User cancelled or doesn't have verified phone
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      List<String> imageUrls = [];
      
      // Upload new images if any
      if (_selectedImages.isNotEmpty) {
        print('📷 Uploading ${_selectedImages.length} images...');
        imageUrls = await _imageService.uploadResponseImages(_selectedImages, widget.request.id);
        print('✅ Images uploaded successfully');
      }
      
      // Keep existing images
      imageUrls.addAll(_existingImageUrls);

      // Build warranty information based on verifications
      String? warrantyInfo;
      List<String> verificationBadges = [];
      
      if (_driverProfile?.status == DriverStatus.approved) {
        verificationBadges.add('Verified Driver');
      }
      if (_driverProfile?.licenseVerification.isVerified == true) {
        verificationBadges.add('Licensed');
      }
      if (_driverProfile?.insuranceVerification.isVerified == true) {
        verificationBadges.add('Insured');
      }
      if (_hasLicense) {
        verificationBadges.add('Licensed Professional');
      }
      if (_hasInsurance) {
        verificationBadges.add('Professional Insurance');
      }
      
      if (verificationBadges.isNotEmpty) {
        warrantyInfo = verificationBadges.join(' • ');
      }

      // Get verified phone numbers to share automatically
      final verifiedPhones = await PhoneVerificationHelper.getVerifiedPhoneNumbers();
      final phoneNumbersToShare = verifiedPhones.map((phone) => phone.number).toList();

      await _responseService.submitResponse(
        requestId: widget.request.id,
        message: _messageController.text.trim(),
        offeredPrice: double.tryParse(_priceController.text.trim()),
        sharedPhoneNumbers: phoneNumbersToShare,
        hasExpiry: false, // Services typically don't have expiry
        expiryDate: null,
        deliveryAvailable: _canProvideOnsite,
        deliveryAmount: null,
        warranty: warrantyInfo,
        images: imageUrls,
        location: _selectedLocation,
        latitude: _latitude,
        longitude: _longitude,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_hasAlreadyResponded 
                ? 'Your service proposal has been updated successfully!' 
                : 'Service proposal submitted successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Update the flag after showing the appropriate message
        setState(() {
          _hasAlreadyResponded = true;
        });
        
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showServiceDetails() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            widget.request.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.attach_money, size: 20, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Budget: LKR ${widget.request.budget.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (widget.request.description.isNotEmpty) ...[
                  const Row(
                    children: [
                      Icon(Icons.description, size: 20, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Service Description',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(widget.request.description),
                  const SizedBox(height: 16),
                ],
                if (widget.request.location.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 20, color: Colors.red),
                      const SizedBox(width: 8),
                      const Text(
                        'Location',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(widget.request.location),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    const Icon(Icons.category, size: 20, color: Colors.purple),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.request.category} > ${widget.request.subcategory}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _getExperienceText(ServiceExperience experience) {
    switch (experience) {
      case ServiceExperience.beginner:
        return 'Beginner (0-1 years)';
      case ServiceExperience.intermediate:
        return 'Intermediate (2-5 years)';
      case ServiceExperience.expert:
        return 'Expert (5+ years)';
      case ServiceExperience.professional:
        return 'Professional/Certified';
    }
  }

  String _getAvailabilityText(AvailabilityType availability) {
    switch (availability) {
      case AvailabilityType.immediate:
        return 'Available Immediately';
      case AvailabilityType.withinWeek:
        return 'Available This Week';
      case AvailabilityType.flexible:
        return 'Flexible Schedule';
      case AvailabilityType.scheduled:
        return 'Scheduled Availability';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _priceController.dispose();
    _experienceYearsController.dispose();
    _certificationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingExistingResponse) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          _hasAlreadyResponded ? 'Update Service Proposal' : 'Submit Service Proposal',
          style: AppTheme.headingMedium,
        ),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Existing response warning
              if (_hasAlreadyResponded) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.amber[600], size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'You have already submitted a proposal',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const SizedBox(width: 28),
                          Expanded(
                            child: Text(
                              'Make your changes and click "Update Proposal" to save',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.amber[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              
              // Service Summary Card
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.request.title,
                            style: AppTheme.headingSmall,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.info_outline, color: AppTheme.primaryColor),
                          onPressed: () => _showServiceDetails(),
                          tooltip: 'More info',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingSmall),
                    Text(
                      'Budget: LKR ${widget.request.budget.toStringAsFixed(0)}',
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.successColor,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXSmall),
                    Text(
                      '${widget.request.category} • ${widget.request.subcategory}',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Service Proposal Details
              Text(
                'Your Service Proposal',
                style: AppTheme.headingSmall,
              ),
              const SizedBox(height: AppTheme.spacingMedium),

              // Service Description Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
                child: TextFormField(
                  controller: _messageController,
                  style: AppTheme.bodyMedium,
                  decoration: AppTheme.inputDecoration(
                    hintText: 'Describe your service, approach, and what you can offer...',
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please describe your service';
                    }
                    if (value.trim().length < 10) {
                      return 'Description must be at least 10 characters';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: AppTheme.spacingMedium),

              // Price Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
                child: TextFormField(
                  controller: _priceController,
                  style: AppTheme.bodyMedium,
                  keyboardType: TextInputType.number,
                  decoration: AppTheme.inputDecoration(
                    hintText: 'Enter your service price',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your price';
                    }
                    final price = double.tryParse(value.trim());
                    if (price == null || price <= 0) {
                      return 'Please enter a valid price';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Experience Level
              Text(
                'Experience Level',
                style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMedium),
                  child: Column(
                    children: ServiceExperience.values.map((experience) {
                      return RadioListTile<ServiceExperience>(
                        title: Text(
                          _getExperienceText(experience),
                          style: AppTheme.bodyMedium,
                        ),
                        value: experience,
                        groupValue: _experienceLevel,
                        activeColor: AppTheme.primaryColor,
                        onChanged: (value) {
                          setState(() {
                            _experienceLevel = value!;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingMedium),

              // Service Delivery Options
              Text(
                'Service Delivery',
                style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMedium),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.computer, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Can Provide Remote Service',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Switch(
                            value: _isRemoteService,
                            onChanged: (value) {
                              setState(() {
                                _isRemoteService = value;
                              });
                            },
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        children: [
                          const Icon(Icons.home_work, color: Colors.orange),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Can Provide On-site Service',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Switch(
                            value: _canProvideOnsite,
                            onChanged: (value) {
                              setState(() {
                                _canProvideOnsite = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Availability
              const Text(
                'Availability',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: AvailabilityType.values.map((availability) {
                      return RadioListTile<AvailabilityType>(
                        title: Text(_getAvailabilityText(availability)),
                        value: availability,
                        groupValue: _availabilityType,
                        onChanged: (value) {
                          setState(() {
                            _availabilityType = value!;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Earliest Available Date
              if (_availabilityType == AvailabilityType.scheduled) ...[
                const Text(
                  'Schedule Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: ListTile(
                          title: Text(
                            _earliestAvailableDate == null
                                ? 'Earliest Available Date'
                                : '${_earliestAvailableDate!.toLocal()}'.split(' ')[0],
                          ),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () => _selectDate(context),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: ListTile(
                          title: Text(
                            _preferredStartTime == null
                                ? 'Start Time'
                                : _preferredStartTime!.format(context),
                          ),
                          trailing: const Icon(Icons.access_time),
                          onTap: () => _selectTime(true),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Card(
                        child: ListTile(
                          title: Text(
                            _preferredEndTime == null
                                ? 'End Time'
                                : _preferredEndTime!.format(context),
                          ),
                          trailing: const Icon(Icons.access_time),
                          onTap: () => _selectTime(false),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Portfolio Images
              const Text(
                'Portfolio Images (Optional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Show examples of your previous work',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      if (_selectedImages.isNotEmpty || _existingImageUrls.isNotEmpty) ...[
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1,
                          ),
                          itemCount: _selectedImages.length + _existingImageUrls.length + 
                                    ((_selectedImages.length + _existingImageUrls.length) < 6 ? 1 : 0),
                          itemBuilder: (context, index) {
                            final totalExisting = _existingImageUrls.length;
                            final totalNew = _selectedImages.length;
                            final totalImages = totalExisting + totalNew;
                            
                            if (index < totalExisting) {
                              // Existing image
                              return Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: NetworkImage(_existingImageUrls[index]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _existingImageUrls.removeAt(index);
                                        });
                                      },
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
                            } else if (index < totalImages) {
                              // New image
                              final newImageIndex = index - totalExisting;
                              return Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: FileImage(_selectedImages[newImageIndex]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedImages.removeAt(newImageIndex);
                                        });
                                      },
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
                              // Add more button
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
                                      Icon(
                                        Icons.add_photo_alternate_outlined,
                                        size: 30,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Add More',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
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
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 48,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add Portfolio Images',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Max 6 images',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Contact Information
              const Text(
                'Contact Information',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.phone, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Share Phone Numbers',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_userPhoneNumbers.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Icon(Icons.phone_disabled, size: 48, color: Colors.grey),
                                const SizedBox(height: 8),
                                const Text(
                                  'No verified phone numbers',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Add and verify phone numbers to share with clients.',
                                  style: TextStyle(color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const PhoneNumberManagementScreen(),
                                      ),
                                    );
                                    _loadUserPhoneNumbers();
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Phone Number'),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Column(
                          children: _userPhoneNumbers.map((phone) {
                            return Card(
                              child: CheckboxListTile(
                                title: Row(
                                  children: [
                                    Expanded(child: Text(phone.number)),
                                    if (phone.isVerified) ...[
                                      const Icon(Icons.verified, color: Colors.green, size: 16),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'Verified',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: phone.isPrimary 
                                    ? const Text('Primary', style: TextStyle(color: Colors.blue))
                                    : null,
                                value: _selectedPhoneNumbers.contains(phone.number),
                                onChanged: phone.isVerified ? (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedPhoneNumbers.add(phone.number);
                                    } else {
                                      _selectedPhoneNumbers.remove(phone.number);
                                    }
                                  });
                                } : null,
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitResponse,
                  style: AppTheme.primaryButtonStyle.copyWith(
                    padding: MaterialStateProperty.all(
                      const EdgeInsets.symmetric(vertical: AppTheme.spacingMedium),
                    ),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: AppTheme.backgroundColor,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          () {
                            final buttonText = _hasAlreadyResponded ? 'Update Service Proposal' : 'Submit Service Proposal';
                            print('🔘 Button text should be: $buttonText (_hasAlreadyResponded = $_hasAlreadyResponded)');
                            return buttonText;
                          }(),
                          style: AppTheme.buttonText.copyWith(
                            color: AppTheme.backgroundColor,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingXLarge),
            ],
          ),
        ),
      ),
    );
  }
}
