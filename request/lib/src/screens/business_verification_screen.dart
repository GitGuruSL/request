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
      appBar: AppBar(
        title: const Text('Business Verification'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Form(
          key: _formKey,
          child: Stepper(
            currentStep: _currentStep,
            onStepTapped: (step) {
              if (step <= _currentStep || _isValidStep(_currentStep)) {
                setState(() => _currentStep = step);
              }
            },
            controlsBuilder: (context, details) {
              return Row(
                children: [
                  if (details.stepIndex < 2)
                    ElevatedButton(
                      onPressed: details.onStepContinue,
                      child: const Text('Continue'),
                    ),
                  if (details.stepIndex == 2)
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitVerification,
                      child: _isLoading 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Submit for Verification'),
                    ),
                  const SizedBox(width: 12),
                  if (details.stepIndex > 0)
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Back'),
                    ),
                ],
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
      ),
    );
  }

  Widget _buildBusinessInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tell us about your business',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        // Business Name
        TextFormField(
          controller: _businessNameController,
          decoration: const InputDecoration(
            labelText: 'Business Name *',
            hintText: 'Enter your business name',
            prefixIcon: Icon(Icons.business),
            border: OutlineInputBorder(),
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
            prefixIcon: Icon(Icons.category),
            border: OutlineInputBorder(),
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
            prefixIcon: Icon(Icons.location_on),
            border: OutlineInputBorder(),
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
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(),
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
            prefixIcon: Icon(Icons.email),
            border: OutlineInputBorder(),
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
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        
        // Business License Image Upload
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                Icons.camera_alt,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                _businessLicenseImage == null
                    ? 'Upload Business License (Optional)'
                    : 'License Document Uploaded',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _pickLicenseImage,
                icon: const Icon(Icons.upload),
                label: const Text('Choose File'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Business Images Upload
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                Icons.photo_library,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                'Upload Business Photos',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_businessImages.length} photos selected',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _pickBusinessImages,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Add Photos'),
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
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(
                dayName,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Checkbox(
              value: _closedDays[day],
              onChanged: (value) {
                setState(() => _closedDays[day] = value ?? false);
              },
            ),
            const Text('Closed'),
            const Spacer(),
            if (!_closedDays[day]!) ...[
              GestureDetector(
                onTap: () => _selectTime(day, true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(_formatTime(_openingHours[day]!)),
                ),
              ),
              const Text(' - '),
              GestureDetector(
                onTap: () => _selectTime(day, false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(_formatTime(_closingHours[day]!)),
                ),
              ),
            ],
          ],
        ),
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            border: Border.all(color: Colors.orange[200]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Verification Process',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Your business information will be reviewed by our team. This process typically takes 1-3 business days. You will be notified once verification is complete.',
                style: TextStyle(
                  color: Colors.orange[700],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              '• $item',
              style: const TextStyle(fontSize: 14),
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
