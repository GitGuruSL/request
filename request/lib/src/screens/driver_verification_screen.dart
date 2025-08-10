import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/enhanced_user_service.dart';
import '../services/file_upload_service.dart';
import '../models/enhanced_user_model.dart';

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
      appBar: AppBar(
        title: const Text('Driver Verification'),
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
                    Expanded(
                      child: ElevatedButton(
                        onPressed: details.onStepCancel,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(details.stepIndex == 2 ? 'Submit' : 'Continue'),
                      ),
                    ),
                  if (details.stepIndex == 2)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitVerification,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
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
                  const SizedBox(width: 8),
                  if (details.stepIndex > 0)
                    OutlinedButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Back'),
                    ),
                ],
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        // License Number
        TextFormField(
          controller: _licenseNumberController,
          decoration: InputDecoration(
            labelText: 'License Number',
            hintText: 'Enter your license number',
            prefixIcon: const Icon(Icons.credit_card),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
        InkWell(
          onTap: _selectLicenseExpiryDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.grey),
                const SizedBox(width: 12),
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
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // License Image Upload
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: _licenseImage != null ? Colors.green : Colors.grey.shade300,
              width: _licenseImage != null ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                _licenseImage != null ? Icons.check_circle : Icons.camera_alt,
                size: 48,
                color: _licenseImage != null ? Colors.green : Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                _licenseImage != null 
                    ? 'License image uploaded'
                    : 'Upload License Photo',
                style: TextStyle(
                  color: _licenseImage != null ? Colors.green : Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _pickLicenseImage,
                icon: Icon(_licenseImage != null ? Icons.edit : Icons.camera_alt),
                label: Text(_licenseImage != null ? 'Change Photo' : 'Take Photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _licenseImage != null 
                      ? Colors.grey[300] 
                      : Theme.of(context).colorScheme.primary,
                  foregroundColor: _licenseImage != null 
                      ? Colors.black87 
                      : Colors.white,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Info box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Please ensure your license is valid and clearly visible in the photo',
                  style: TextStyle(
                    color: Colors.blue[700],
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        // Vehicle Make and Model
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _vehicleMakeController,
                decoration: InputDecoration(
                  labelText: 'Make',
                  hintText: 'e.g., Toyota',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                decoration: InputDecoration(
                  labelText: 'Model',
                  hintText: 'e.g., Camry',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                decoration: InputDecoration(
                  labelText: 'Year',
                  hintText: '2020',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                decoration: InputDecoration(
                  labelText: 'Seats',
                  hintText: '4',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                decoration: InputDecoration(
                  labelText: 'License Plate',
                  hintText: 'ABC-1234',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                decoration: InputDecoration(
                  labelText: 'Color',
                  hintText: 'White',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: _vehicleImages.isNotEmpty ? Colors.green : Colors.grey.shade300,
              width: _vehicleImages.isNotEmpty ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                _vehicleImages.isNotEmpty ? Icons.check_circle : Icons.add_a_photo,
                size: 48,
                color: _vehicleImages.isNotEmpty ? Colors.green : Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                _vehicleImages.isEmpty
                    ? 'Add Vehicle Photos'
                    : '${_vehicleImages.length} photo${_vehicleImages.length == 1 ? '' : 's'} added',
                style: TextStyle(
                  color: _vehicleImages.isNotEmpty ? Colors.green : Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _pickVehicleImages,
                icon: const Icon(Icons.add_a_photo),
                label: Text(_vehicleImages.isEmpty ? 'Add Photos' : 'Add More Photos'),
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
                        borderRadius: BorderRadius.circular(8),
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
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
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Verification Process',
                    style: TextStyle(
                      color: Colors.orange[700],
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
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
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
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              item,
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
