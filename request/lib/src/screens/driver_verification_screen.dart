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
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _insuranceNumberController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehicleYearController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  
  DateTime? _licenseExpiryDate;
  DateTime? _insuranceExpiryDate;
  
  // Document files
  File? _driverImage;                    // Driver's photo
  File? _licenseFrontPhoto;              // New: License front photo
  File? _licenseBackPhoto;               // New: License back photo
  File? _licenseDocument;                // Additional license document (optional)
  File? _insuranceDocument;              // Vehicle insurance document
  File? _vehicleRegistrationDocument;    // Vehicle registration document
  List<File> _vehicleImages = [];        // Vehicle photos (4 images)
  
  bool _isLoading = false;
  bool _isUploading = false;

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
          _fullNameController.text = user.name ?? '';
          _phoneController.text = user.phoneNumber ?? '';
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
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
    super.dispose();
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
                'Driver Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _fullNameController,
            decoration: const InputDecoration(
              labelText: 'Full Name *',
              prefixIcon: Icon(Icons.person_outline),
              border: InputBorder.none,
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your full name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number *',
              prefixIcon: Icon(Icons.phone),
              border: InputBorder.none,
              filled: true,
              fillColor: Colors.white,
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your phone number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _licenseNumberController,
            decoration: const InputDecoration(
              labelText: 'License Number *',
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
                        ? 'License Expiry Date *'
                        : 'License Expiry: ${_licenseExpiryDate!.day}/${_licenseExpiryDate!.month}/${_licenseExpiryDate!.year}',
                    style: TextStyle(
                      color: _licenseExpiryDate == null ? Colors.grey[600] : Colors.black,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
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
                'Required Documents',
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
              color: Colors.blue.withOpacity(0.1),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Please upload clear, high-quality photos. You can use camera or gallery.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildDocumentUpload(
            'Driver Photo',
            'Upload or capture your photo (required for verification)',
            _driverImage,
            () => _pickDocument('driver_image'),
            Icons.person,
            isRequired: true,
          ),
          const SizedBox(height: 16),
          _buildDocumentUpload(
            'Driving License - Front Side',
            'Upload or capture the front side of your driving license',
            _licenseFrontPhoto,
            () => _pickDocument('license_front'),
            Icons.credit_card,
            isRequired: true,
          ),
          const SizedBox(height: 16),
          _buildDocumentUpload(
            'Driving License - Back Side',
            'Upload or capture the back side of your driving license',
            _licenseBackPhoto,
            () => _pickDocument('license_back'),
            Icons.flip_to_back,
            isRequired: true,
          ),
          const SizedBox(height: 16),
          _buildDocumentUpload(
            'Additional License Document',
            'Upload additional license document if available (optional)',
            _licenseDocument,
            () => _pickDocument('license_document'),
            Icons.badge,
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
                    color: _insuranceExpiryDate == null ? Colors.grey[600] : Colors.black,
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
              Icon(Icons.directions_car, color: AppTheme.primaryColor, size: 24),
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
            itemCount: _vehicleImages.length < 6 ? _vehicleImages.length + 1 : 6,
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
          border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid, width: 2),
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

  Widget _buildDocumentUpload(String title, String description, File? file, VoidCallback onTap, IconData icon, {bool isRequired = false}) {
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
    return _fullNameController.text.trim().isNotEmpty &&
           _phoneController.text.trim().isNotEmpty &&
           _licenseNumberController.text.trim().isNotEmpty &&
           _licenseExpiryDate != null &&
           _driverImage != null &&                    // Driver photo required
           _licenseFrontPhoto != null &&              // License front photo required
           _licenseBackPhoto != null &&               // License back photo required
           _insuranceNumberController.text.trim().isNotEmpty &&
           _insuranceExpiryDate != null &&            // Insurance expiry date required
           _insuranceDocument != null &&              // Vehicle insurance required
           _vehicleModelController.text.trim().isNotEmpty &&
           _vehicleYearController.text.trim().isNotEmpty &&
           _vehicleColorController.text.trim().isNotEmpty &&
           _vehicleNumberController.text.trim().isNotEmpty &&
           _vehicleRegistrationDocument != null &&   // Vehicle registration required
           _vehicleImages.length >= 4 &&             // Minimum 4 vehicle photos
           !_isLoading;
  }

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
      String? driverImageUrl, licenseFrontUrl, licenseBackUrl, licenseDocumentUrl, insuranceUrl, registrationUrl;
      List<String> vehicleImageUrls = [];

      // Upload driver photo (required)
      if (_driverImage != null) {
        driverImageUrl = await _fileUploadService.uploadDriverDocument(
          currentUser.uid, _driverImage!, 'driver_photo'
        );
      }

      // Upload license front photo (required)
      if (_licenseFrontPhoto != null) {
        licenseFrontUrl = await _fileUploadService.uploadDriverDocument(
          currentUser.uid, _licenseFrontPhoto!, 'license_front'
        );
      }

      // Upload license back photo (required)
      if (_licenseBackPhoto != null) {
        licenseBackUrl = await _fileUploadService.uploadDriverDocument(
          currentUser.uid, _licenseBackPhoto!, 'license_back'
        );
      }

      // Upload additional license document (optional)
      if (_licenseDocument != null) {
        licenseDocumentUrl = await _fileUploadService.uploadDriverDocument(
          currentUser.uid, _licenseDocument!, 'license_document'
        );
      }

      // Upload vehicle insurance document (required)
      if (_insuranceDocument != null) {
        insuranceUrl = await _fileUploadService.uploadDriverDocument(
          currentUser.uid, _insuranceDocument!, 'vehicle_insurance'
        );
      }

      // Upload vehicle registration document (required)
      if (_vehicleRegistrationDocument != null) {
        registrationUrl = await _fileUploadService.uploadDriverDocument(
          currentUser.uid, _vehicleRegistrationDocument!, 'vehicle_registration'
        );
      }

      // Upload vehicle images
      for (int i = 0; i < _vehicleImages.length; i++) {
        final imageUrl = await _fileUploadService.uploadVehicleImage(
          currentUser.uid, _vehicleImages[i], i + 1
        );
        vehicleImageUrls.add(imageUrl);
      }

      // Create driver verification data
      final driverData = {
        'userId': currentUser.uid,
        'name': _fullNameController.text.trim(),
        'email': currentUser.email,
        'phoneNumber': _phoneController.text.trim(),
        'licenseNumber': _licenseNumberController.text.trim(),
        'licenseExpiry': _licenseExpiryDate,
        'insuranceNumber': _insuranceNumberController.text.trim(),
        'insuranceExpiry': _insuranceExpiryDate,
        'vehicleModel': _vehicleModelController.text.trim(),
        'vehicleYear': int.parse(_vehicleYearController.text.trim()),
        'vehicleColor': _vehicleColorController.text.trim(),
        'vehicleNumber': _vehicleNumberController.text.trim(),
        'vehicleType': 'car', // Default
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
        'driverImageUrl': driverImageUrl,                    // Driver photo
        'licenseFrontUrl': licenseFrontUrl,                  // License front photo
        'licenseBackUrl': licenseBackUrl,                    // License back photo
        'licenseDocumentUrl': licenseDocumentUrl,            // Additional license document (optional)
        'insuranceDocumentUrl': insuranceUrl,                // Vehicle insurance
        'vehicleRegistrationUrl': registrationUrl,           // Vehicle registration
        'vehicleImageUrls': vehicleImageUrls,
        
        // Verification status for each document/image
        'documentVerification': {
          'driverImage': {'status': 'pending', 'submittedAt': DateTime.now()},           // Driver photo
          'licenseFront': {'status': 'pending', 'submittedAt': DateTime.now()},          // License front
          'licenseBack': {'status': 'pending', 'submittedAt': DateTime.now()},           // License back
          'licenseDocument': licenseDocumentUrl != null 
            ? {'status': 'pending', 'submittedAt': DateTime.now()} : null,               // Optional: License document
          'vehicleInsurance': {'status': 'pending', 'submittedAt': DateTime.now()},      // Vehicle insurance
          'vehicleRegistration': {'status': 'pending', 'submittedAt': DateTime.now()},   // Vehicle registration
        },
        'vehicleImageVerification': _vehicleImages.asMap().entries.map((entry) => {
          'imageIndex': entry.key,
          'status': 'pending',
          'submittedAt': DateTime.now(),
          'imageType': entry.key == 0 ? 'front_with_plate' : 
                      entry.key == 1 ? 'rear_with_plate' : 'additional',
        }).toList(),
      };

      // Save to Firestore
      await _userService.submitDriverVerification(driverData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Driver verification submitted successfully! We\'ll review your documents within 1-3 business days.'),
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
}
