import 'package:flutter/material.dart';
import '../services/enhanced_user_service.dart';
import '../theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import '../services/file_upload_service.dart';
import 'dart:io';

class BusinessRegistrationScreen extends StatefulWidget {
  const BusinessRegistrationScreen({Key? key}) : super(key: key);

  @override
  State<BusinessRegistrationScreen> createState() => _BusinessRegistrationScreenState();
}

class _BusinessRegistrationScreenState extends State<BusinessRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final EnhancedUserService _userService = EnhancedUserService();
  final FileUploadService _fileUploadService = FileUploadService();
  
  // Business Information Controllers
  final _businessNameController = TextEditingController();
  final _businessEmailController = TextEditingController();
  final _businessPhoneController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _businessDescriptionController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _taxIdController = TextEditingController();
  
  // Business Category
  String? _selectedCategory;
  final List<String> _businessCategories = [
    'Delivery Service',
    'Restaurant',
    'Retail Store',
    'Grocery',
    'Pharmacy',
    'Electronics',
    'Clothing',
    'Hardware',
    'Services',
    'Other',
  ];
  
  // Business Documents
  File? _businessLicenseFile;
  File? _taxCertificateFile;
  File? _insuranceDocumentFile;
  File? _businessLogoFile;
  
  String? _businessLicenseUrl;
  String? _taxCertificateUrl;
  String? _insuranceDocumentUrl;
  String? _businessLogoUrl;
  
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  Future<void> _loadCurrentUserData() async {
    try {
      final currentUser = await _userService.getCurrentUser();
      if (currentUser != null) {
        setState(() {
          _businessEmailController.text = currentUser.email ?? '';
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessEmailController.dispose();
    _businessPhoneController.dispose();
    _businessAddressController.dispose();
    _businessDescriptionController.dispose();
    _licenseNumberController.dispose();
    _taxIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Business Registration'),
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
              _buildHeader(),
              const SizedBox(height: 24),
              _buildBusinessInformationSection(),
              const SizedBox(height: 24),
              _buildBusinessDocumentsSection(),
              const SizedBox(height: 24),
              _buildBusinessLogoSection(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.business, color: AppTheme.primaryColor, size: 32),
              const SizedBox(width: 12),
              const Text(
                'Business Registration',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Complete your business registration to start offering services on our platform.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessInformationSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.business_center, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Business Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _businessNameController,
            label: 'Business Name *',
            hint: 'Enter your business name',
            prefixIcon: Icons.business,
            validator: (value) => value?.isEmpty ?? true ? 'Business name is required' : null,
          ),
          _buildTextField(
            controller: _businessEmailController,
            label: 'Business Email *',
            hint: 'Enter business email',
            prefixIcon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Business email is required';
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value!)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          _buildTextField(
            controller: _businessPhoneController,
            label: 'Business Phone *',
            hint: 'Enter business phone number',
            prefixIcon: Icons.phone,
            keyboardType: TextInputType.phone,
            validator: (value) => value?.isEmpty ?? true ? 'Business phone is required' : null,
          ),
          _buildTextField(
            controller: _businessAddressController,
            label: 'Business Address *',
            hint: 'Enter complete business address',
            prefixIcon: Icons.location_on,
            maxLines: 3,
            validator: (value) => value?.isEmpty ?? true ? 'Business address is required' : null,
          ),
          _buildTextField(
            controller: _businessDescriptionController,
            label: 'Business Description *',
            hint: 'Describe your business and services',
            prefixIcon: Icons.description,
            maxLines: 4,
            validator: (value) => value?.isEmpty ?? true ? 'Business description is required' : null,
          ),
          _buildDropdownField(),
          _buildTextField(
            controller: _licenseNumberController,
            label: 'Business License Number',
            hint: 'Enter business license number (optional)',
            prefixIcon: Icons.assignment,
          ),
          _buildTextField(
            controller: _taxIdController,
            label: 'Tax ID / VAT Number',
            hint: 'Enter tax ID or VAT number (optional)',
            prefixIcon: Icons.receipt,
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessDocumentsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Business Documents',
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
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Please upload clear, high-quality photos of your documents. Supported formats: JPG, PNG, PDF.',
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
            title: 'Business License',
            description: 'Official business registration/license document (optional)',
            file: _businessLicenseFile,
            url: _businessLicenseUrl,
            onTap: () => _pickDocument('business_license'),
            isRequired: false,
          ),
          _buildDocumentUpload(
            title: 'Tax Certificate',
            description: 'Tax registration certificate (if applicable)',
            file: _taxCertificateFile,
            url: _taxCertificateUrl,
            onTap: () => _pickDocument('tax_certificate'),
            isRequired: false,
          ),
          _buildDocumentUpload(
            title: 'Insurance Document',
            description: 'Business insurance certificate (if applicable)',
            file: _insuranceDocumentFile,
            url: _insuranceDocumentUrl,
            onTap: () => _pickDocument('insurance'),
            isRequired: false,
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessLogoSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.image, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Business Logo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLogoUpload(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int? maxLines,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            maxLines: maxLines ?? 1,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AppTheme.textSecondary.withOpacity(0.5),
                fontSize: 14,
              ),
              prefixIcon: Icon(prefixIcon, color: AppTheme.primaryColor, size: 20),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(8),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(8),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Business Category *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            hint: const Text('Select business category'),
            validator: (value) => value == null ? 'Business category is required' : null,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.category, color: AppTheme.primaryColor, size: 20),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(8),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(8),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: _businessCategories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentUpload({
    required String title,
    required String description,
    required File? file,
    required String? url,
    required VoidCallback onTap,
    required bool isRequired,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.upload_file, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              if (isRequired)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Required',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          if (file != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'File selected: ${file!.path.split('/').last}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(
                file != null ? Icons.refresh : Icons.camera_alt,
                size: 16,
              ),
              label: Text(file != null ? 'Change File' : 'Choose File'),
              style: OutlinedButton.styleFrom(
                side: BorderSide.none,
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoUpload() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          if (_businessLogoFile != null) ...[
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _businessLogoFile!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ] else ...[
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.business,
                size: 40,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'No logo selected',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _pickDocument('business_logo'),
              icon: Icon(
                _businessLogoFile != null ? Icons.refresh : Icons.camera_alt,
                size: 16,
              ),
              label: Text(_businessLogoFile != null ? 'Change Logo' : 'Choose Logo'),
              style: OutlinedButton.styleFrom(
                side: BorderSide.none,
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submitBusinessRegistration,
        icon: _isSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.business_center),
        label: Text(_isSubmitting ? 'Submitting...' : 'Submit for Verification'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDocument(String documentType) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          switch (documentType) {
            case 'business_license':
              _businessLicenseFile = File(pickedFile.path);
              break;
            case 'tax_certificate':
              _taxCertificateFile = File(pickedFile.path);
              break;
            case 'insurance':
              _insuranceDocumentFile = File(pickedFile.path);
              break;
            case 'business_logo':
              _businessLogoFile = File(pickedFile.path);
              break;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitBusinessRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final currentUser = await _userService.getCurrentUser();
      if (currentUser == null) throw Exception('User not authenticated');

      // Upload documents if selected
      String? businessLicenseUrl;
      String? taxCertificateUrl;
      String? insuranceDocumentUrl;
      String? businessLogoUrl;

      if (_businessLicenseFile != null) {
        businessLicenseUrl = await _fileUploadService.uploadBusinessDocument(
          currentUser.uid,
          _businessLicenseFile!,
          'business_license',
        );
      }

      if (_taxCertificateFile != null) {
        taxCertificateUrl = await _fileUploadService.uploadBusinessDocument(
          currentUser.uid,
          _taxCertificateFile!,
          'tax_certificate',
        );
      }

      if (_insuranceDocumentFile != null) {
        insuranceDocumentUrl = await _fileUploadService.uploadBusinessDocument(
          currentUser.uid,
          _insuranceDocumentFile!,
          'insurance_document',
        );
      }

      if (_businessLogoFile != null) {
        businessLogoUrl = await _fileUploadService.uploadBusinessDocument(
          currentUser.uid,
          _businessLogoFile!,
          'business_logo',
        );
      }

      // Prepare business registration data
      final businessData = {
        'userId': currentUser.uid,
        'businessName': _businessNameController.text.trim(),
        'businessEmail': _businessEmailController.text.trim(),
        'businessPhone': _businessPhoneController.text.trim(),
        'businessAddress': _businessAddressController.text.trim(),
        'businessDescription': _businessDescriptionController.text.trim(),
        'businessCategory': _selectedCategory,
        'licenseNumber': _licenseNumberController.text.trim(),
        'taxId': _taxIdController.text.trim().isEmpty ? null : _taxIdController.text.trim(),
        'status': 'pending',
        'isVerified': false,
        'submittedAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        // Document URLs
        'businessLicenseUrl': businessLicenseUrl,
        'taxCertificateUrl': taxCertificateUrl,
        'insuranceDocumentUrl': insuranceDocumentUrl,
        'businessLogoUrl': businessLogoUrl,
        // Document status tracking
        'businessLicenseStatus': 'pending',
        'taxCertificateStatus': taxCertificateUrl != null ? 'pending' : null,
        'insuranceDocumentStatus': insuranceDocumentUrl != null ? 'pending' : null,
        'businessLogoStatus': businessLogoUrl != null ? 'pending' : null,
        // Document verification nested structure
        'documentVerification': {
          'businessLicense': {
            'status': 'pending',
            'submittedAt': DateTime.now(),
          },
          if (taxCertificateUrl != null)
            'taxCertificate': {
              'status': 'pending',
              'submittedAt': DateTime.now(),
            },
          if (insuranceDocumentUrl != null)
            'insurance': {
              'status': 'pending',
              'submittedAt': DateTime.now(),
            },
          if (businessLogoUrl != null)
            'businessLogo': {
              'status': 'pending',
              'uploadedAt': DateTime.now(),
            },
        },
      };

      // Submit to Firestore
      await _userService.submitBusinessVerification(businessData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Business registration submitted successfully! We\'ll review your information and get back to you within 2-5 business days.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );

        // Navigate back to main dashboard
        Navigator.pushReplacementNamed(context, '/main-dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting registration: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
