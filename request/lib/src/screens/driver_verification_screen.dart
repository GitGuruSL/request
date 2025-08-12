import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/enhanced_user_service.dart';
import '../services/file_upload_service.dart';
import '../models/enhanced_user_model.dart';
import '../theme/app_theme.dart';

class DriverVerificationScreen extends StatefulWidget {
  const DriverVerificationScreen({Key? key}) : super(key: key);

  @override
  State<DriverVerificationScreen> createState() => _DriverVerificationScreenState();
}

class _DriverVerificationScreenState extends State<DriverVerificationScreen> {
  final EnhancedUserService _userService = EnhancedUserService();
  final FileUploadService _fileUploadService = FileUploadService();
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _licenseNumberController = TextEditingController();
  final _vehicleMakeController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehicleYearController = TextEditingController();
  final _plateNumberController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _seatingCapacityController = TextEditingController();
  
  DateTime? _licenseExpiryDate;
  File? _licenseImage;
  List<File> _vehicleImages = [];
  bool _isLoading = false;
  bool _isUploading = false;
  int _currentStep = 0;

  @override
  void dispose() {
    _licenseNumberController.dispose();
    _vehicleMakeController.dispose();
    _vehicleModelController.dispose();
    _vehicleYearController.dispose();
    _plateNumberController.dispose();
    _vehicleColorController.dispose();
    _seatingCapacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Driver Verification'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: AppTheme.backgroundColor,
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
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  children: [
                    if (details.stepIndex < 2)
                      Expanded(
                        child: Container(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: details.onStepContinue,
                            style: AppTheme.primaryButtonStyle,
                            child: Text(details.stepIndex == 2 ? 'Submit' : 'Continue'),
                          ),
                        ),
                      ),
                    if (details.stepIndex == 2)
                      Expanded(
                        child: Container(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitVerification,
                            style: AppTheme.primaryButtonStyle,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Submit for Verification'),
                          ),
                        ),
                      ),
                    if (details.stepIndex > 0) const SizedBox(width: 12),
                    if (details.stepIndex > 0)
                      Container(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: details.onStepCancel,
                          style: AppTheme.secondaryButtonStyle,
                          child: const Text('Back'),
                        ),
                      ),
                  ],
                ),
              );
            },
            onStepContinue: () {
              if (_isValidStep(_currentStep)) {
                setState(() {
                  if (_currentStep < 2) {
                    _currentStep++;
                  } else {
                    _submitVerification();
                  }
                });
              }
            },
            onStepCancel: () {
              setState(() {
                if (_currentStep > 0) {
                  _currentStep--;
                }
              });
            },
            steps: [
              Step(
                title: const Text('License Information'),
                content: _buildLicenseStep(),
                isActive: _currentStep >= 0,
                state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              ),
              Step(
                title: const Text('Vehicle Details'),
                content: _buildVehicleStep(),
                isActive: _currentStep >= 1,
                state: _currentStep > 1 ? StepState.complete : 
                       _currentStep == 1 ? StepState.indexed : StepState.disabled,
              ),
              Step(
                title: const Text('Review & Submit'),
                content: _buildReviewStep(),
                isActive: _currentStep >= 2,
                state: _currentStep == 2 ? StepState.indexed : StepState.disabled,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLicenseStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Driver\'s License Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        
        // License Number
        TextFormField(
          controller: _licenseNumberController,
          decoration: const InputDecoration(
            labelText: 'License Number',
            hintText: 'Enter your license number',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'License number is required';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        // License Expiry Date
        Text(
          'License Expiry Date',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectLicenseExpiryDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: AppTheme.inputDecoration,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _licenseExpiryDate == null
                        ? 'Select license expiry date'
                        : 'Expires: ${_formatDate(_licenseExpiryDate!)}',
                    style: TextStyle(
                      color: _licenseExpiryDate == null 
                          ? Colors.grey[600] 
                          : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // License Image Upload
        Text(
          'License Photo',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.cardDecoration,
          child: Column(
            children: [
              Icon(
                _licenseImage != null ? Icons.check_circle_outline : Icons.camera_alt_outlined,
                size: 48,
                color: _licenseImage != null ? AppTheme.primaryColor : Colors.grey[600],
              ),
              const SizedBox(height: 8),
              Text(
                _licenseImage != null 
                    ? 'License image uploaded'
                    : 'Upload License Photo',
                style: TextStyle(
                  color: _licenseImage != null ? AppTheme.primaryColor : Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: _pickLicenseImage,
                  icon: Icon(_licenseImage != null ? Icons.edit : Icons.camera_alt),
                  label: Text(_licenseImage != null ? 'Change Photo' : 'Take Photo'),
                  style: AppTheme.primaryButtonStyle,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Info box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: AppTheme.cardDecoration,
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Please ensure your license is valid and clearly visible in the photo',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vehicle Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        
        // Vehicle Make and Model
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _vehicleMakeController,
                decoration: const InputDecoration(
                  labelText: 'Make',
                  hintText: 'e.g., Toyota',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vehicle make is required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _vehicleModelController,
                decoration: const InputDecoration(
                  labelText: 'Model',
                  hintText: 'e.g., Camry',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vehicle model is required';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Year and Seating Capacity
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _vehicleYearController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Year',
                  hintText: '2020',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Year is required';
                  }
                  final year = int.tryParse(value);
                  if (year == null || year < 2000 || year > DateTime.now().year + 1) {
                    return 'Enter a valid year';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _seatingCapacityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Seats',
                  hintText: '4',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Seating capacity is required';
                  }
                  final seats = int.tryParse(value);
                  if (seats == null || seats < 2 || seats > 8) {
                    return 'Enter valid seating capacity (2-8)';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Plate Number and Color
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _plateNumberController,
                decoration: const InputDecoration(
                  labelText: 'License Plate',
                  hintText: 'ABC-1234',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'License plate is required';
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
                  labelText: 'Color',
                  hintText: 'White',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vehicle color is required';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Vehicle Images Upload
        Text(
          'Vehicle Photos',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.cardDecoration,
          child: Column(
            children: [
              Icon(
                _vehicleImages.isNotEmpty ? Icons.check_circle_outline : Icons.add_a_photo_outlined,
                size: 48,
                color: _vehicleImages.isNotEmpty ? AppTheme.primaryColor : Colors.grey[600],
              ),
              const SizedBox(height: 8),
              Text(
                _vehicleImages.isEmpty
                    ? 'Add Vehicle Photos'
                    : '${_vehicleImages.length} photo${_vehicleImages.length == 1 ? '' : 's'} added',
                style: TextStyle(
                  color: _vehicleImages.isNotEmpty ? AppTheme.primaryColor : Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: _pickVehicleImages,
                  icon: const Icon(Icons.add_a_photo),
                  label: Text(_vehicleImages.isEmpty ? 'Add Photos' : 'Add More Photos'),
                  style: AppTheme.primaryButtonStyle,
                ),
              ),
            ],
          ),
        ),
        
        if (_vehicleImages.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _vehicleImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(0),
                        child: Image.file(
                          _vehicleImages[index],
                          width: 80,
                          height: 80,
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
                              color: Colors.black,
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
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review Your Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        
        // License Information Summary
        _buildInfoCard(
          'License Information',
          [
            'License Number: ${_licenseNumberController.text}',
            'Expires: ${_licenseExpiryDate != null ? _formatDate(_licenseExpiryDate!) : 'Not set'}',
            'Photo: ${_licenseImage != null ? 'Uploaded' : 'Not uploaded'}',
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Vehicle Information Summary
        _buildInfoCard(
          'Vehicle Information',
          [
            'Make & Model: ${_vehicleMakeController.text} ${_vehicleModelController.text}',
            'Year: ${_vehicleYearController.text}',
            'License Plate: ${_plateNumberController.text}',
            'Color: ${_vehicleColorController.text}',
            'Seating Capacity: ${_seatingCapacityController.text} passengers',
            'Photos: ${_vehicleImages.length} uploaded',
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Terms and Conditions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(0),
            border: Border.all(color: Colors.grey),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Verification Process',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Your information will be reviewed by our team. This process typically takes 1-2 business days. You\'ll receive a notification once your driver profile is approved.',
                style: TextStyle(
                  color: Colors.grey[700],
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
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(0),
              border: Border.all(color: Colors.grey),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Uploading documents...'),
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
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              item,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
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
        return _licenseNumberController.text.trim().isNotEmpty &&
               _licenseExpiryDate != null &&
               _licenseImage != null;
      case 1:
        return _vehicleMakeController.text.trim().isNotEmpty &&
               _vehicleModelController.text.trim().isNotEmpty &&
               _vehicleYearController.text.trim().isNotEmpty &&
               _plateNumberController.text.trim().isNotEmpty &&
               _vehicleColorController.text.trim().isNotEmpty &&
               _seatingCapacityController.text.trim().isNotEmpty &&
               _vehicleImages.isNotEmpty;
      case 2:
        return true; // Review step is always valid if reached
      default:
        return false;
    }
  }

  Future<void> _selectLicenseExpiryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (date != null) {
      setState(() => _licenseExpiryDate = date);
    }
  }

  Future<void> _pickLicenseImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    
    if (image != null) {
      setState(() => _licenseImage = File(image.path));
    }
  }

  Future<void> _pickVehicleImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    
    if (images != null && images.isNotEmpty) {
      setState(() {
        _vehicleImages.addAll(images.map((image) => File(image.path)));
      });
    }
  }

  void _removeVehicleImage(int index) {
    setState(() {
      _vehicleImages.removeAt(index);
    });
  }

  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate() || !_isValidStep(2)) return;

    setState(() => _isLoading = true);
    setState(() => _isUploading = true);

    try {
      final currentUser = _userService.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Upload license image
      String? licenseImageUrl;
      if (_licenseImage != null) {
        licenseImageUrl = await FileUploadService.uploadImage(
          imageFile: _licenseImage!,
          path: 'users/${currentUser.uid}/verification',
          fileName: 'license.jpg',
        );
      }

      // Upload vehicle images
      List<String> vehicleImageUrls = [];
      for (int i = 0; i < _vehicleImages.length; i++) {
        final url = await FileUploadService.uploadImage(
          imageFile: _vehicleImages[i],
          path: 'users/${currentUser.uid}/vehicle',
          fileName: 'image_$i.jpg',
        );
        if (url != null) {
          vehicleImageUrls.add(url);
        }
      }

      // Create driver data
      final driverData = DriverData(
        licenseNumber: _licenseNumberController.text.trim(),
        licenseExpiry: _licenseExpiryDate!,
        licenseImageUrl: licenseImageUrl,
        vehicle: VehicleInfo(
          make: _vehicleMakeController.text.trim(),
          model: _vehicleModelController.text.trim(),
          year: _vehicleYearController.text.trim(),
          plateNumber: _plateNumberController.text.trim(),
          color: _vehicleColorController.text.trim(),
          seatingCapacity: int.parse(_seatingCapacityController.text.trim()),
          vehicleImages: vehicleImageUrls,
        ),
      );

      // Update user role data
      await _userService.updateRoleData(
        userId: currentUser.uid,
        role: UserRole.driver,
        data: driverData.toMap(),
      );

      // Submit for verification
      await _userService.submitRoleForVerification(
        userId: currentUser.uid,
        role: UserRole.driver,
      );

      // Show success and navigate
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Driver verification submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacementNamed(context, '/main-dashboard');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting verification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
      setState(() => _isUploading = false);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
