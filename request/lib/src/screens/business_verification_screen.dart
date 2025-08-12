import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/enhanced_user_service.dart';
import '../services/file_upload_service.dart';
import '../models/enhanced_user_model.dart';

class BusinessVerificationScreen extends StatefulWidget {
  const BusinessVerificationScreen({Key? key}) : super(key: key);

  @override
  State<BusinessVerificationScreen> createState() => _BusinessVerificationScreenState();
}

class _BusinessVerificationScreenState extends State<BusinessVerificationScreen> {
  final EnhancedUserService _userService = EnhancedUserService();
  final FileUploadService _fileUploadService = FileUploadService();
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _businessNameController = TextEditingController();
  final _businessTypeController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _businessPhoneController = TextEditingController();
  final _businessEmailController = TextEditingController();
  final _businessLicenseController = TextEditingController();
  
  // Business hours controllers
  Map<String, TimeOfDay> _openingHours = {
    'monday': const TimeOfDay(hour: 9, minute: 0),
    'tuesday': const TimeOfDay(hour: 9, minute: 0),
    'wednesday': const TimeOfDay(hour: 9, minute: 0),
    'thursday': const TimeOfDay(hour: 9, minute: 0),
    'friday': const TimeOfDay(hour: 9, minute: 0),
    'saturday': const TimeOfDay(hour: 9, minute: 0),
    'sunday': const TimeOfDay(hour: 9, minute: 0),
  };
  
  Map<String, TimeOfDay> _closingHours = {
    'monday': const TimeOfDay(hour: 18, minute: 0),
    'tuesday': const TimeOfDay(hour: 18, minute: 0),
    'wednesday': const TimeOfDay(hour: 18, minute: 0),
    'thursday': const TimeOfDay(hour: 18, minute: 0),
    'friday': const TimeOfDay(hour: 18, minute: 0),
    'saturday': const TimeOfDay(hour: 18, minute: 0),
    'sunday': const TimeOfDay(hour: 18, minute: 0),
  };
  
  Map<String, bool> _closedDays = {
    'monday': false,
    'tuesday': false,
    'wednesday': false,
    'thursday': false,
    'friday': false,
    'saturday': false,
    'sunday': true,
  };
  
  File? _businessLicenseImage;
  List<File> _businessImages = [];
  bool _isLoading = false;
  bool _isUploading = false;
  int _currentStep = 0;
  bool _is24x7 = false;

  final List<String> _businessTypes = [
    'Restaurant/Food Service',
    'Retail Store',
    'Professional Services',
    'Healthcare',
    'Automotive',
    'Beauty/Personal Care',
    'Education/Training',
    'Technology',
    'Construction',
    'Real Estate',
    'Entertainment',
    'Delivery Service (DPD, UPS, DHL, etc.)',
    'Logistics & Transport',
    'Other',
  ];

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessTypeController.dispose();
    _businessAddressController.dispose();
    _businessPhoneController.dispose();
    _businessEmailController.dispose();
    _businessLicenseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Business Verification'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepTapped: (step) {
            if (step <= _currentStep || _isValidStep(_currentStep)) {
              setState(() => _currentStep = step);
            }
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  if (details.stepIndex < 2)
                    ElevatedButton(
                      onPressed: details.onStepContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: const RoundedRectangleBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: const Text('Continue'),
                    ),
                  if (details.stepIndex == 2)
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitVerification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: const RoundedRectangleBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
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
                          : const Text('Submit for Verification'),
                    ),
                  const SizedBox(width: 16),
                  if (details.stepIndex > 0)
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: const Text(
                        'Back',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('Business Information'),
              content: _buildBusinessInfoStep(),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 
                  ? StepState.complete 
                  : _currentStep == 0 
                      ? StepState.indexed 
                      : StepState.disabled,
            ),
            Step(
              title: const Text('Business Hours & Documents'),
              content: _buildHoursDocumentsStep(),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 
                  ? StepState.complete 
                  : _currentStep == 1 
                      ? StepState.indexed 
                      : StepState.disabled,
            ),
            Step(
              title: const Text('Review & Submit'),
              content: _buildReviewStep(),
              isActive: _currentStep >= 2,
              state: _currentStep == 2 
                  ? StepState.indexed 
                  : StepState.disabled,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessInfoStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tell us about your business',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          
          // Business Name
          TextFormField(
            controller: _businessNameController,
            decoration: const InputDecoration(
              labelText: 'Business Name *',
              hintText: 'Enter your business name',
              prefixIcon: Icon(Icons.business, color: Colors.grey),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your business name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Business Type
          DropdownButtonFormField<String>(
            value: _businessTypeController.text.isEmpty ? null : _businessTypeController.text,
            decoration: const InputDecoration(
              labelText: 'Business Type *',
              prefixIcon: Icon(Icons.category, color: Colors.grey),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: true,
              fillColor: Colors.white,
            ),
            items: _businessTypes.map((type) => DropdownMenuItem(
              value: type,
              child: Text(type),
            )).toList(),
            onChanged: (value) {
              setState(() => _businessTypeController.text = value ?? '');
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select your business type';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Business Address
          TextFormField(
            controller: _businessAddressController,
            decoration: const InputDecoration(
              labelText: 'Business Address *',
              hintText: 'Enter your business address',
              prefixIcon: Icon(Icons.location_on, color: Colors.grey),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: true,
              fillColor: Colors.white,
            ),
            maxLines: 2,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your business address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Business Phone
          TextFormField(
            controller: _businessPhoneController,
            decoration: const InputDecoration(
              labelText: 'Business Phone *',
              hintText: 'Enter your business phone number',
              prefixIcon: Icon(Icons.phone, color: Colors.grey),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: true,
              fillColor: Colors.white,
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your business phone number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Business Email
          TextFormField(
            controller: _businessEmailController,
            decoration: const InputDecoration(
              labelText: 'Business Email *',
              hintText: 'Enter your business email',
              prefixIcon: Icon(Icons.email, color: Colors.grey),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: true,
              fillColor: Colors.white,
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your business email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHoursDocumentsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Business Hours & Documentation',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        // 24/7 Option
        SwitchListTile(
          title: const Text('Open 24/7'),
          subtitle: const Text('Check if your business operates 24 hours'),
          value: _is24x7,
          onChanged: (value) {
            setState(() => _is24x7 = value);
          },
        ),
        
        if (!_is24x7) ...[
          const SizedBox(height: 16),
          Text(
            'Operating Hours',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          
          ..._closedDays.keys.map((day) => _buildDayHours(day)).toList(),
        ],
        
        const SizedBox(height: 24),
        
        // Business License
        TextFormField(
          controller: _businessLicenseController,
          decoration: const InputDecoration(
            labelText: 'Business License Number',
            hintText: 'Enter your business license number (optional)',
            prefixIcon: Icon(Icons.assignment),
            border: InputBorder.none,
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        
        // Business License Image Upload
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: Column(
            children: [
              Icon(
                Icons.camera_alt,
                size: 48,
                color: Colors.grey,
              ),
              const SizedBox(height: 12),
              Text(
                _businessLicenseImage == null
                    ? 'Upload Business License (Optional)'
                    : 'License Document Uploaded',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickLicenseImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const RoundedRectangleBorder(),
                ),
                child: const Text('Choose File'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Business Images Upload
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: Column(
            children: [
              Icon(
                Icons.photo_library,
                size: 48,
                color: Colors.grey,
              ),
              const SizedBox(height: 12),
              const Text(
                'Upload Business Photos',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_businessImages.length} photos selected',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickBusinessImages,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const RoundedRectangleBorder(),
                ),
                child: const Text('Add Photos'),
              ),
            ],
          ),
        ),
        
        if (_businessImages.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _businessImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _businessImages[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: GestureDetector(
                        onTap: () => _removeBusinessImage(index),
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
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDayHours(String day) {
    final dayName = day.substring(0, 1).toUpperCase() + day.substring(1);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              dayName,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
          Checkbox(
            value: _closedDays[day],
            onChanged: (value) {
              setState(() => _closedDays[day] = value ?? false);
            },
            activeColor: Colors.black,
          ),
          const Text('Closed'),
          const Spacer(),
          if (!_closedDays[day]!) ...[
            GestureDetector(
              onTap: () => _selectTime(day, true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: Text(
                  _formatTime(_openingHours[day]!),
                  style: const TextStyle(color: Colors.black),
                ),
              ),
            ),
            const Text(' - ', style: TextStyle(color: Colors.grey)),
            GestureDetector(
              onTap: () => _selectTime(day, false),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: Text(
                  _formatTime(_closingHours[day]!),
                  style: const TextStyle(color: Colors.black),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review Your Business Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        // Business Information Summary
        _buildInfoCard(
          'Business Information',
          [
            'Name: ${_businessNameController.text}',
            'Type: ${_businessTypeController.text}',
            'Address: ${_businessAddressController.text}',
            'Phone: ${_businessPhoneController.text}',
            'Email: ${_businessEmailController.text}',
            if (_businessLicenseController.text.isNotEmpty)
              'License: ${_businessLicenseController.text}',
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Hours Summary
        _buildInfoCard(
          'Operating Hours',
          [
            if (_is24x7)
              'Open 24/7'
            else
              ..._closedDays.entries.where((entry) => !entry.value).map((entry) {
                final day = entry.key.substring(0, 1).toUpperCase() + entry.key.substring(1);
                return '$day: ${_formatTime(_openingHours[entry.key]!)} - ${_formatTime(_closingHours[entry.key]!)}';
              }).toList(),
            if (_closedDays.entries.where((entry) => entry.value).isNotEmpty)
              'Closed: ${_closedDays.entries.where((entry) => entry.value).map((e) => e.key.substring(0, 1).toUpperCase() + e.key.substring(1)).join(', ')}',
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Documents Summary
        _buildInfoCard(
          'Documents & Photos',
          [
            'Business License: ${_businessLicenseImage != null ? 'Uploaded' : 'Not provided'}',
            'Business Photos: ${_businessImages.length} uploaded',
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Terms and Conditions
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.black,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Verification Process',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Your business information will be reviewed by our team. This process typically takes 1-3 business days. You will be notified once verification is complete.',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Upload Progress
        if (_isUploading)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                const Text('Uploading documents and photos...'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildInfoCard(String title, List<String> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              item,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          )),
        ],
      ),
    );
  }

  bool _isValidStep(int step) {
    switch (step) {
      case 0:
        return _businessNameController.text.trim().isNotEmpty &&
               _businessTypeController.text.trim().isNotEmpty &&
               _businessAddressController.text.trim().isNotEmpty &&
               _businessPhoneController.text.trim().isNotEmpty &&
               _businessEmailController.text.trim().isNotEmpty &&
               RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_businessEmailController.text);
      case 1:
        return true; // Hours and documents are optional
      case 2:
        return true; // Review step is always valid if reached
      default:
        return false;
    }
  }

  Future<void> _selectTime(String day, bool isOpening) async {
    final time = await showTimePicker(
      context: context,
      initialTime: isOpening ? _openingHours[day]! : _closingHours[day]!,
    );
    
    if (time != null) {
      setState(() {
        if (isOpening) {
          _openingHours[day] = time;
        } else {
          _closingHours[day] = time;
        }
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _pickLicenseImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    
    if (image != null) {
      setState(() => _businessLicenseImage = File(image.path));
    }
  }

  Future<void> _pickBusinessImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    
    if (images != null && images.isNotEmpty) {
      setState(() {
        _businessImages.addAll(images.map((image) => File(image.path)));
      });
    }
  }

  void _removeBusinessImage(int index) {
    setState(() {
      _businessImages.removeAt(index);
    });
  }

  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate() || !_isValidStep(2)) return;

    setState(() => _isLoading = true);
    setState(() => _isUploading = true);

    try {
      final currentUser = _userService.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Upload business license image
      String? businessLicenseImageUrl;
      if (_businessLicenseImage != null) {
        businessLicenseImageUrl = await FileUploadService.uploadImage(
          imageFile: _businessLicenseImage!,
          path: 'users/${currentUser.uid}/business',
          fileName: 'license.jpg',
        );
      }

      // Upload business images
      List<String> businessImageUrls = [];
      for (int i = 0; i < _businessImages.length; i++) {
        final url = await FileUploadService.uploadImage(
          imageFile: _businessImages[i],
          path: 'users/${currentUser.uid}/business',
          fileName: 'image_$i.jpg',
        );
        if (url != null) {
          businessImageUrls.add(url);
        }
      }

      // Create business hours
      final weeklyHours = <String, TimeSlot>{};
      for (final day in _closedDays.keys) {
        if (_closedDays[day]!) {
          weeklyHours[day] = TimeSlot(
            startTime: '09:00',
            endTime: '18:00',
            isClosed: true,
          );
        } else {
          weeklyHours[day] = TimeSlot(
            startTime: _formatTime(_openingHours[day]!),
            endTime: _formatTime(_closingHours[day]!),
            isClosed: false,
          );
        }
      }

      final businessHours = BusinessHours(
        weeklyHours: weeklyHours,
        is24x7: _is24x7,
      );

      // Create business data
      final businessData = BusinessData(
        businessName: _businessNameController.text.trim(),
        businessType: _businessTypeController.text.trim(),
        businessAddress: _businessAddressController.text.trim(),
        businessPhone: _businessPhoneController.text.trim(),
        businessEmail: _businessEmailController.text.trim(),
        businessLicense: _businessLicenseController.text.trim().isEmpty 
            ? null 
            : _businessLicenseController.text.trim(),
        businessLicenseImageUrl: businessLicenseImageUrl,
        businessImages: businessImageUrls,
        businessHours: businessHours,
      );

      // Update user role data
      await _userService.updateRoleData(
        userId: currentUser.uid,
        role: UserRole.business,
        data: businessData.toMap(),
      );

      // Submit for verification
      await _userService.submitRoleForVerification(
        userId: currentUser.uid,
        role: UserRole.business,
      );

      // Show success and navigate
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Business verification submitted successfully! We\'ll review your information and get back to you within 1-3 business days.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );

        Navigator.pushReplacementNamed(context, '/main-dashboard');
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
        setState(() => _isUploading = false);
      }
    }
  }
}
